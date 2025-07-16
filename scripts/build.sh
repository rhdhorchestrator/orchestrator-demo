#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUGME:-}" ]] && set -x

script_name="${BASH_SOURCE:-$0}"
script_path="$(realpath "$script_name")"
script_dir_path="$(dirname "$script_path")"

# Logger functions
RED='\033[0;31m'
YELLOW='\033[0;33m'
DEFAULT='\033[0m'

function log_warning() {
  local message="$1"

  echo >&2 -e "${YELLOW}WARN: ${message}${DEFAULT}"
}

function log_error() {
  local message="$1"

  echo >&2 -e "${RED}ERROR: ${message}${DEFAULT}"
}

function log_info() {
  local message="$1"

  echo >&2 -e "INFO: ${message}"
}

# Helper functions
function is_macos {
    [[ "$(uname)" == Darwin ]]
}

# A wrapper for the find command that uses the -E flag on macOS.
# Extended regex (ERE) is not supported by default on macOS.
function findw {
    if is_macos; then
        find -E "$@"
    else
        find "$@"
    fi
}

function get_workflow_id {
    local workdir="$1"
    local workflow_file=""
    local workflow_id=""

    workflow_file=$(findw "$workdir" -type f -regex '.*\.sw\.ya?ml$')
    if [ -z "$workflow_file" ]; then
        log_error "No workflow file found with *.sw.yaml or *.sw.yml suffix"
        return 10
    fi

    workflow_id=$(yq '.id | downcase' "$workflow_file" 2>/dev/null)
    if [ -z "$workflow_id" ]; then
        log_error "The workflow file doesn't seem to have an 'id' property."
        return 11
    fi

    echo "$workflow_id"
}

function container_engine {
    $(command -v docker || command -v podman ) "$@"
}

function assert_optarg_not_empty {
    local arg="$1"

    if [[ -z "${arg#*=}" ]]; then
        log_error "Option --${arg%=*} requires an argument when specified."
        return 12
    fi
}

function usage {
    cat <<EOF
This script performs the following tasks in this specific order:
1. Generates a list of Operator manifests for a SonataFlow project using the kn-workflow plugin (requires exactly v1.35.0)
2. Builds the workflow image using podman or docker
3. Optionally, deploys the application:
    - Pushes the workflow image to the container registry specified by the image path
    - Applies the generated manifests using kubectl in the current k8s namespace

Usage: 
    $script_name [flags]

Flags:
    -i|--image=<string> (required)       The full container image path to use for the workflow, e.g: quay.io/orchestrator/demo:latest.
    -b|--builder-image=<string>          Overrides the image to use for building the workflow image.
    -r|--runtime-image=<string>          Overrides the image to use for running the workflow.
    -n|--namespace=<string>              The target namespace where the manifests will be applied. Default: current namespace.
    -m|--manifests-directory=<string>    The operator manifests will be generated inside the specified directory. Default: 'manifests' directory in the current directory.
    -w|--workflow-directory=<string>     Path to the directory containing the workflow's files. For Quarkus projects, this should be the directory containing 'src'. For non-Quarkus layout, this should be the directory containing the workflow files directly. Default: current directory.
    -P|--no-persistence                  Skips adding persistence configuration to the sonataflow CR.
    -S|--non-quarkus                     Use non-Quarkus layout where workflow resources are in the project root instead of src/main/resources.
       --push                            Pushes the workflow image to the container registry.
       --deploy                          Deploys the application.
    -h|--help                            Prints this help message.

Notes: 
    - This script respects the 'QUARKUS_EXTENSIONS' and 'MAVEN_ARGS_APPEND' environment variables.
    - Use --non-quarkus for non-Quarkus projects where workflow files (.sw.yaml, schemas/, etc.) are in the project root directory.
    - Without --non-quarkus, the script expects Quarkus project structure with resources in src/main/resources/.
EOF
}

declare -A args
args["image"]=""
args["deploy"]=""
args["push"]=""
args["namespace"]=""
args["builder-image"]=""
args["runtime-image"]=""
args["no-persistence"]=""
args["non-quarkus"]=""
args["workflow-directory"]="$PWD"
args["manifests-directory"]="$PWD/manifests"

function parse_args {
    while getopts ":i:b:r:n:m:w:hPS-:" opt; do
        case $opt in
            h) usage; exit ;;
            P) args["no-persistence"]="YES" ;;
            S) args["non-quarkus"]="YES" ;;
            i) args["image"]="$OPTARG" ;;
            n) args["namespace"]="$OPTARG" ;;
            m) args["manifests-directory"]="$(realpath "$OPTARG" 2>/dev/null || echo "$PWD/$OPTARG")" ;;
            w) args["workflow-directory"]="$(realpath "$OPTARG")" ;;
            b) args["builder-image"]="$OPTARG" ;;
            r) args["runtime-image"]="$OPTARG" ;;
            -)
                case "${OPTARG}" in
                    help)
                        usage; exit ;;
                    deploy)
                        args["deploy"]="YES"
                        args["push"]="YES"
                    ;;
                    push)
                        args["push"]="YES" ;;
                    no-persistence)
                        args["no-persistence"]="YES" ;;
                    non-quarkus)
                        args["non-quarkus"]="YES" ;;
                    image=*)
                        assert_optarg_not_empty "$OPTARG" || exit $?
                        args["image"]="${OPTARG#*=}"
                    ;;
                    namespace=*)
                        assert_optarg_not_empty "$OPTARG" || exit $?
                        args["namespace"]="${OPTARG#*=}"
                    ;;
                    manifests-directory=*)
                        assert_optarg_not_empty "$OPTARG" || exit $?
                        args["manifests-directory"]="$(realpath "${OPTARG#*=}" 2>/dev/null || echo "$PWD/${OPTARG#*=}")"
                    ;;
                    workflow-directory=*)
                        assert_optarg_not_empty "$OPTARG" || exit $?
                        args["workflow-directory"]="$(realpath "${OPTARG#*=}")" ;;
                    builder-image=*)
                        assert_optarg_not_empty "$OPTARG" || exit $?
                        args["builder-image"]="${OPTARG#*=}"
                    ;;
                    runtime-image=*)
                        assert_optarg_not_empty "$OPTARG" || exit $?
                        args["runtime-image"]="${OPTARG#*=}"
                    ;;
                    *) log_error "Invalid option: --$OPTARG"; usage; exit 1 ;;
                esac
            ;;
            \?) log_error "Invalid option: -$OPTARG"; usage; exit 2 ;;
            :) log_error "Option -$OPTARG requires an argument."; usage; exit 3 ;;
        esac
    done

    if [[ -z "${args["image"]:-}" ]]; then
        log_error "Missing required flag: --image"
        usage; exit 4
    fi
}

function gen_manifests {
    local res_dir_path
    if [[ -n "${args["non-quarkus"]:-}" ]]; then
        res_dir_path="${args["workflow-directory"]}"
        log_info "Using non-Quarkus layout: resources in project root"
    else
        res_dir_path="${args["workflow-directory"]}/src/main/resources"
        log_info "Using Quarkus layout: resources in src/main/resources"
    fi
    
    local workflow_id
    workflow_id="$(get_workflow_id "$res_dir_path")"

    cd "$res_dir_path"
    log_info "Switched directory: $res_dir_path"

    local gen_manifest_args=(
        -c="${args["manifests-directory"]}"
        --profile='gitops'
        --image="${args["image"]}"
    )
    if [[ -z "${args["namespace"]:-}" ]]; then
        gen_manifest_args+=(--skip-namespace)
    else
        gen_manifest_args+=(--namespace="${args["namespace"]}")
    fi
    kn-workflow gen-manifest "${gen_manifest_args[@]}"        

    cd "${args["workflow-directory"]}"
    log_info "Switched directory: ${args["workflow-directory"]}"

    # Find the sonataflow CR for the workflow
    local sonataflow_cr
    sonataflow_cr="$(findw "${args["manifests-directory"]}" -type f -name "*-sonataflow_${workflow_id}.yaml")"

    if [[ -z "${args["no-persistence"]:-}" ]]; then
        yq --inplace ".spec |= (
            . + {
                \"persistence\": {
                    \"postgresql\": {
                        \"secretRef\": {
                            \"name\": \"sonataflow-psql-postgresql\",
                            \"userKey\": \"postgres-username\",
                            \"passwordKey\": \"postgres-password\"
                        },
                        \"serviceRef\": {
                            \"name\": \"sonataflow-psql-postgresql\",
                            \"port\": 5432,
                            \"databaseName\": \"sonataflow\",
                            \"databaseSchema\": \"${workflow_id}\"
                        }
                    }
                }
            }
        )" "${sonataflow_cr}"
        log_info "Added persistence configuration to the sonataflow CR"
    fi
}

function build_image {
    local image_name="${args["image"]%:*}"
    local tag="${args["image"]#*:}"

    # Base extensions that are always included
    local base_quarkus_extensions="\
    io.quarkiverse.openapi.generator:quarkus-openapi-generator:2.9.1-lts,\
    org.kie:kie-addons-quarkus-monitoring-sonataflow,\
    org.kie:kogito-addons-quarkus-jobs-knative-eventing"

    # Add persistence extensions only when persistence is enabled
    if [[ -z "${args["no-persistence"]:-}" ]]; then
        base_quarkus_extensions="${base_quarkus_extensions},\
        org.kie:kie-addons-quarkus-persistence-jdbc,\
        io.quarkus:quarkus-jdbc-postgresql:3.15.4.redhat-00001,\
        io.quarkus:quarkus-agroal:3.15.4.redhat-00001"
    fi

    # The 'maxYamlCodePoints' parameter contols the maximum size for YAML input files. 
    # Set to 35000000 characters which is ~33MB in UTF-8.  
    local base_maven_args_append="-DmaxYamlCodePoints=35000000"
    
    # Add persistence configuration only when persistence is enabled
    if [[ -z "${args["no-persistence"]:-}" ]]; then
        base_maven_args_append="${base_maven_args_append} \
        -Dkogito.persistence.type=jdbc \
        -Dquarkus.datasource.db-kind=postgresql \
        -Dkogito.persistence.proto.marshaller=false"
    fi
    
    if [[ -n "${QUARKUS_EXTENSIONS:-}" ]]; then
        base_quarkus_extensions="${base_quarkus_extensions},${QUARKUS_EXTENSIONS}"
    fi

    if [[ -n "${MAVEN_ARGS_APPEND:-}" ]]; then
        base_maven_args_append="${base_maven_args_append} ${MAVEN_ARGS_APPEND}"
    fi

    # Build specifically for linux/amd64 to ensure compatibility with OSL v1.35.0
    local container_args=(
        -f="$script_dir_path/../docker/osl.Dockerfile"
        --tag="${args["image"]}"
        --platform='linux/amd64'
        --ulimit='nofile=4096:4096'
        --build-arg="QUARKUS_EXTENSIONS=${base_quarkus_extensions}"
        --build-arg="MAVEN_ARGS_APPEND=${base_maven_args_append}"
    )
    [[ -n "${args["builder-image"]:-}" ]] && container_args+=(--build-arg="BUILDER_IMAGE=${args["builder-image"]}")
    [[ -n "${args["runtime-image"]:-}" ]] && container_args+=(--build-arg="RUNTIME_IMAGE=${args["runtime-image"]}")

    container_engine build "${container_args[@]}" "${args["workflow-directory"]}"

    if ! git rev-parse --short=8 HEAD >/dev/null 2>&1; then
        log_info "Failed to get the git commit hash, skipping tagging with commit hash"
    else
        local commit_hash
        commit_hash=$(git rev-parse --short=8 HEAD)
        container_engine tag "${args["image"]}" "$image_name:$commit_hash"
    fi

    if [[ "$tag" != "latest" ]]; then
        container_engine tag "${args["image"]}" "$image_name:latest"
    fi

    log_info "Workflow image built with tags:"
    container_engine images --filter="reference=$image_name" --format="{{.Repository}}:{{.Tag}}"
}

function push {
    local image_name="${args["image"]%:*}"
    local tag="${args["image"]#*:}"

    container_engine push "${args["image"]}"

    if ! git rev-parse --short=8 HEAD >/dev/null 2>&1; then
        log_info "Failed to get the git commit hash, skipping image push with commit hash as tag"
    else
        local commit_hash
        commit_hash=$(git rev-parse --short=8 HEAD)
        container_engine push "$image_name:$commit_hash"
    fi

    if [[ "$tag" != "latest" ]]; then
        container_engine push "$image_name:latest"
    fi
}

parse_args "$@"

gen_manifests
build_image

if [[ -n "${args["push"]}" ]]; then
    log_info "Pushing the workflow image to ${args["image"]%/*}"
    push
fi

if [[ -n "${args["deploy"]}" ]]; then
    log_info "Applying the generated manifests"
    kubectl apply -f "${args["manifests-directory"]}"
fi
