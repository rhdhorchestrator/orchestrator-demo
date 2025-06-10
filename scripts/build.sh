#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUGME:-}" ]] && set -x

script_name="${BASH_SOURCE:-$0}"
script_path="$(realpath "$script_name")"
script_dir_path="$(dirname "$script_path")"

# shellcheck disable=SC1091
source "${script_dir_path}/lib/_logger.sh"
# shellcheck disable=SC1091
source "${script_dir_path}/lib/_functions.sh"

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
    -w|--workflow-directory=<string>     Path to the directory containing the workflow's files (the 'src' directory). Default: current directory.
    -P|--no-persistence                  Skips adding persistence configuration to the sonataflow CR.
       --push                            Pushes the workflow image to the container registry.
       --deploy                          Deploys the application.
    -h|--help                            Prints this help message.

Notes: 
    - This script respects the 'QUARKUS_EXTENSIONS' and 'MAVEN_ARGS_APPEND' environment variables.
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
args["workflow-directory"]="$PWD"
args["manifests-directory"]="$PWD/manifests"

function parse_args {
    while getopts ":i:b:r:n:m:w:hP-:" opt; do
        case $opt in
            h) usage; exit ;;
            P) args["no-persistence"]="YES" ;;
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
    local res_dir_path="${args["workflow-directory"]}/src/main/resources"
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

    if [[ -f "${res_dir_path}/secret.properties" ]]; then
        yq --inplace ".spec.podTemplate.container.envFrom=[{\"secretRef\": { \"name\": \"${workflow_id}-secrets\"}}]" "${sonataflow_cr}"
        create_secret_args=(
            --from-env-file="$res_dir_path/secret.properties"
            --dry-run=client
            -o=yaml
        )
        if [[ -z "${args["namespace"]}" ]]; then
            create_secret_args+=(--namespace="${args["namespace"]}")
        fi
        kubectl create secret generic "${workflow_id}-secrets" "${create_secret_args[@]}" > "${args["manifests-directory"]}/00-secret_${workflow_id}-secrets.yaml"
        log_info "Generated k8s secret for the workflow"
     fi

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

    # These add-ons enable the use of JDBC for persisting workflow states and correlation
    # contexts in serverless workflow applications.
    local base_quarkus_extensions="\
    io.quarkiverse.openapi.generator:quarkus-openapi-generator:2.9.1-lts,\
    org.kie:kie-addons-quarkus-monitoring-sonataflow,\
    org.kie:kogito-addons-quarkus-jobs-knative-eventing,\
    org.kie:kie-addons-quarkus-persistence-jdbc,\
    io.quarkus:quarkus-jdbc-postgresql:3.15.4.redhat-00001,\
    io.quarkus:quarkus-agroal:3.15.4.redhat-00001"

    # The 'maxYamlCodePoints' parameter contols the maximum size for YAML input files. 
    # Set to 35000000 characters which is ~33MB in UTF-8.  
    local base_maven_args_append="\
    -DmaxYamlCodePoints=35000000 \
    -Dkogito.persistence.type=jdbc \
    -Dquarkus.datasource.db-kind=postgresql \
    -Dkogito.persistence.proto.marshaller=false"
    
    if [[ -n "${QUARKUS_EXTENSIONS:-}" ]]; then
        base_quarkus_extensions="${base_quarkus_extensions},${QUARKUS_EXTENSIONS}"
    fi

    if [[ -n "${MAVEN_ARGS_APPEND:-}" ]]; then
        base_maven_args_append="${base_maven_args_append} ${MAVEN_ARGS_APPEND}"
    fi

    # Build specifically for linux/amd64 to ensure compatibility with OSL v1.35.0
    local pocker_args=(
        -f="$script_dir_path/../docker/osl.Dockerfile"
        --tag="${args["image"]}"
        --platform='linux/amd64'
        --ulimit='nofile=4096:4096'
        --build-arg="QUARKUS_EXTENSIONS=${base_quarkus_extensions}"
        --build-arg="MAVEN_ARGS_APPEND=${base_maven_args_append}"
    )
    [[ -n "${args["builder-image"]:-}" ]] && pocker_args+=(--build-arg="BUILDER_IMAGE=${args["builder-image"]}")
    [[ -n "${args["runtime-image"]:-}" ]] && pocker_args+=(--build-arg="RUNTIME_IMAGE=${args["runtime-image"]}")

    pocker build "${pocker_args[@]}" "${args["workflow-directory"]}"

    if ! git rev-parse --short=8 HEAD >/dev/null 2>&1; then
        log_info "Failed to get the git commit hash, skipping tagging with commit hash"
    else
        local commit_hash=$(git rev-parse --short=8 HEAD)
        pocker tag "${args["image"]}" "$image_name:$commit_hash"
    fi

    if [[ "$tag" != "latest" ]]; then
        pocker tag "${args["image"]}" "$image_name:latest"
    fi

    log_info "Workflow image built with tags:"
    pocker images --filter="reference=$image_name" --format="{{.Repository}}:{{.Tag}}"
}

function push {
    local image_name="${args["image"]%:*}"
    local tag="${args["image"]#*:}"

    pocker push "${args["image"]}"

    if ! git rev-parse --short=8 HEAD >/dev/null 2>&1; then
        log_info "Failed to get the git commit hash, skipping image push with commit hash as tag"
    else
        local commit_hash=$(git rev-parse --short=8 HEAD)
        pocker push "$image_name:$commit_hash"
    fi

    if [[ "$tag" != "latest" ]]; then
        pocker push "$image_name:latest"
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
