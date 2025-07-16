#!/usr/bin/env bash

set -euo pipefail
[[ -n "${DEBUGME:-}" ]] && set -x

script_name="${BASH_SOURCE:-$0}"
script_path="$(realpath "$script_name")"
script_dir_path="$(dirname "$script_path")"

# Logger functions
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
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

function log_success() {
  local message="$1"

  echo >&2 -e "${GREEN}SUCCESS: ${message}${DEFAULT}"
}

# Dependency validation
function check_dependencies() {
    local missing_deps=()
    local required_tools=("kn-workflow" "yq" "git")
    
    # Detect and validate container engine
    if [[ -n "${args["container-engine"]:-}" ]]; then
        # Use user-specified container engine
        if ! command -v "${args["container-engine"]}" >/dev/null 2>&1; then
            missing_deps+=("${args["container-engine"]}")
        else
            DETECTED_CONTAINER_ENGINE="${args["container-engine"]}"
            log_info "Using specified container engine: ${args["container-engine"]}"
        fi
    else
        # Auto-detect container engine
        if command -v docker >/dev/null 2>&1; then
            DETECTED_CONTAINER_ENGINE="docker"
            log_info "Auto-detected container engine: docker"
        elif command -v podman >/dev/null 2>&1; then
            DETECTED_CONTAINER_ENGINE="podman"
            log_info "Auto-detected container engine: podman"
        else
            missing_deps+=("docker or podman")
        fi
    fi
    
    # Check for kubectl only if deploy flag is set
    if [[ -n "${args["deploy"]:-}" ]] && ! command -v kubectl >/dev/null 2>&1; then
        missing_deps+=("kubectl")
    fi
    
    # Check required tools
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_deps+=("$tool")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install the missing tools and try again."
        return 13
    fi
    
    log_info "All dependencies are available"
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

function validate_image_name() {
    local image="$1"
    
    # Basic validation for image name format
    if [[ ! "$image" =~ ^[a-zA-Z0-9._/-]+:[a-zA-Z0-9._-]+$ ]]; then
        log_error "Invalid image name format: $image"
        log_error "Expected format: registry/image:tag"
        return 14
    fi
}

function validate_directory() {
    local dir="$1"
    local description="$2"
    
    if [[ ! -d "$dir" ]]; then
        log_error "$description directory does not exist: $dir"
        return 15
    fi
}

function get_workflow_id {
    local workdir="$1"
    local workflow_file=""
    local workflow_id=""

    workflow_file=$(findw "$workdir" -type f -regex '.*\.sw\.ya?ml$')
    if [ -z "$workflow_file" ]; then
        log_error "No workflow file found with *.sw.yaml or *.sw.yml suffix in: $workdir"
        return 10
    fi

    workflow_id=$(yq '.id | downcase' "$workflow_file" 2>/dev/null)
    if [ -z "$workflow_id" ]; then
        log_error "The workflow file doesn't seem to have an 'id' property: $workflow_file"
        return 11
    fi

    echo "$workflow_id"
}

function container_engine {
    if [[ -z "$DETECTED_CONTAINER_ENGINE" ]]; then
        log_error "Container engine not detected. Please run dependency check first."
        return 16
    fi
    
    "$DETECTED_CONTAINER_ENGINE" "$@"
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
1. Generates a list of Operator manifests for a SonataFlow project using the kn-workflow plugin (>= v1.36.0)
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
    -c|--container-engine=<string>       Container engine to use (docker or podman). Default: auto-detect.
    -P|--no-persistence                  Skips adding persistence configuration to the sonataflow CR.
    -S|--non-quarkus                     Use non-Quarkus layout where workflow resources are in the project root instead of src/main/resources.
       --push                            Pushes the workflow image to the container registry.
       --deploy                          Deploys the application.
    -h|--help                            Prints this help message.

Notes: 
    - This script respects the 'QUARKUS_EXTENSIONS' and 'MAVEN_ARGS_APPEND' environment variables.
    - Use --non-quarkus for non-Quarkus projects where workflow files (.sw.yaml, schemas/, etc.) are in the project root directory.
    - Without --non-quarkus, the script expects Quarkus project structure with resources in src/main/resources/.
    - Use --container-engine to specify docker or podman. If not specified, the script will auto-detect which one is available.
EOF
}

declare -A args
args["image"]=""
args["deploy"]=""
args["push"]=""
args["namespace"]=""
args["builder-image"]=""
args["runtime-image"]=""
args["container-engine"]=""
args["no-persistence"]=""
args["non-quarkus"]=""
args["workflow-directory"]="$PWD"
args["manifests-directory"]="$PWD/manifests"

# Global variable to store the detected container engine
DETECTED_CONTAINER_ENGINE=""

function parse_args {
    while getopts ":i:b:r:n:m:w:c:hPS-:" opt; do
        case $opt in
            h) usage; exit ;;
            P) args["no-persistence"]="YES" ;;
            S) args["non-quarkus"]="YES" ;;
            i) args["image"]="$OPTARG" ;;
            n) args["namespace"]="$OPTARG" ;;
            m) args["manifests-directory"]="$(realpath "$OPTARG" 2>/dev/null || echo "$PWD/$OPTARG")" ;;
            w) args["workflow-directory"]="$(realpath "$OPTARG")" ;;
            c) args["container-engine"]="$OPTARG" ;;
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
                    container-engine=*)
                        assert_optarg_not_empty "$OPTARG" || exit $?
                        args["container-engine"]="${OPTARG#*=}"
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
    
    # Validate inputs
    validate_image_name "${args["image"]}"
    validate_directory "${args["workflow-directory"]}" "Workflow"
    
    # Validate container engine if specified
    if [[ -n "${args["container-engine"]:-}" ]]; then
        if [[ "${args["container-engine"]}" != "docker" && "${args["container-engine"]}" != "podman" ]]; then
            log_error "Invalid container engine: ${args["container-engine"]}"
            log_error "Supported container engines: docker, podman"
            exit 27
        fi
    fi
    
    # Create manifests directory if it doesn't exist
    mkdir -p "${args["manifests-directory"]}"
}

function gen_manifests {
    log_info "=== Generating Kubernetes manifests ==="
    
    local res_dir_path
    if [[ -n "${args["non-quarkus"]:-}" ]]; then
        res_dir_path="${args["workflow-directory"]}"
        log_info "Using non-Quarkus layout: resources in project root"
    else
        res_dir_path="${args["workflow-directory"]}/src/main/resources"
        log_info "Using Quarkus layout: resources in src/main/resources"
    fi
    
    # Validate resource directory exists
    validate_directory "$res_dir_path" "Workflow resources"
    
    local workflow_id
    workflow_id="$(get_workflow_id "$res_dir_path")"
    log_info "Found workflow ID: $workflow_id"

    cd "$res_dir_path"
    log_info "Switched directory: $res_dir_path"

    local gen_manifest_args=(
        -c="${args["manifests-directory"]}"
        --profile='gitops'
        --image="${args["image"]}"
    )
    if [[ -z "${args["namespace"]:-}" ]]; then
        gen_manifest_args+=(--skip-namespace)
        log_info "Generating manifests without namespace"
    else
        gen_manifest_args+=(--namespace="${args["namespace"]}")
        log_info "Generating manifests for namespace: ${args["namespace"]}"
    fi
    
    log_info "Running: kn-workflow gen-manifest ${gen_manifest_args[*]}"
    if ! kn-workflow gen-manifest "${gen_manifest_args[@]}"; then
        log_error "Failed to generate manifests"
        return 17
    fi
    
    cd "${args["workflow-directory"]}"
    log_info "Switched directory: ${args["workflow-directory"]}"

    # Find the sonataflow CR for the workflow
    local sonataflow_cr
    sonataflow_cr="$(findw "${args["manifests-directory"]}" -type f -name "*-sonataflow_${workflow_id}.yaml")"
    
    if [[ -z "$sonataflow_cr" ]]; then
        log_error "Could not find sonataflow CR for workflow: $workflow_id"
        return 18
    fi
    
    log_info "Found sonataflow CR: $sonataflow_cr"

    if [[ -z "${args["no-persistence"]:-}" ]]; then
        log_info "Adding persistence configuration to sonataflow CR"
        if ! yq --inplace ".spec |= (
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
        )" "${sonataflow_cr}"; then
            log_error "Failed to add persistence configuration"
            return 19
        fi
        log_success "Added persistence configuration to sonataflow CR"
    else
        log_info "Skipping persistence configuration"
    fi
    
    log_success "Manifests generated successfully in: ${args["manifests-directory"]}"
}

function build_image {
    log_info "=== Building workflow image ==="
    
    local image_name="${args["image"]%:*}"
    local tag="${args["image"]#*:}"
    
    log_info "Building image: ${args["image"]}"
    log_info "Image name: $image_name"
    log_info "Tag: $tag"
    log_info "Container engine: $DETECTED_CONTAINER_ENGINE"

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
        log_info "Including persistence extensions"
    else
        log_info "Skipping persistence extensions"
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
        log_info "Added custom extensions: ${QUARKUS_EXTENSIONS}"
    fi

    if [[ -n "${MAVEN_ARGS_APPEND:-}" ]]; then
        base_maven_args_append="${base_maven_args_append} ${MAVEN_ARGS_APPEND}"
        log_info "Added custom Maven args: ${MAVEN_ARGS_APPEND}"
    fi

    # Validate Dockerfile exists
    local dockerfile_path="$script_dir_path/../docker/osl.Dockerfile"
    if [[ ! -f "$dockerfile_path" ]]; then
        log_error "Dockerfile not found: $dockerfile_path"
        return 20
    fi

    # Build specifically for linux/amd64 to ensure compatibility with OSL v1.35.0
    local container_args=(
        -f="$dockerfile_path"
        --tag="${args["image"]}"
        --platform='linux/amd64'
        --ulimit='nofile=4096:4096'
        --build-arg="QUARKUS_EXTENSIONS=${base_quarkus_extensions}"
        --build-arg="MAVEN_ARGS_APPEND=${base_maven_args_append}"
    )
    [[ -n "${args["builder-image"]:-}" ]] && container_args+=(--build-arg="BUILDER_IMAGE=${args["builder-image"]}")
    [[ -n "${args["runtime-image"]:-}" ]] && container_args+=(--build-arg="RUNTIME_IMAGE=${args["runtime-image"]}")

    log_info "Starting container build (this may take several minutes)..."
    if ! container_engine build "${container_args[@]}" "${args["workflow-directory"]}"; then
        log_error "Container build failed"
        return 21
    fi
    
    log_success "Container build completed successfully"

    # Tag with git commit hash if available
    if ! git rev-parse --short=8 HEAD >/dev/null 2>&1; then
        log_warning "Failed to get git commit hash, skipping commit tag"
    else
        local commit_hash
        commit_hash=$(git rev-parse --short=8 HEAD)
        log_info "Tagging with commit hash: $commit_hash"
        container_engine tag "${args["image"]}" "$image_name:$commit_hash"
    fi

    # Tag with latest if not already latest
    if [[ "$tag" != "latest" ]]; then
        log_info "Tagging with 'latest' tag"
        container_engine tag "${args["image"]}" "$image_name:latest"
    fi

    log_success "Image built successfully with tags:"
    container_engine images --filter="reference=$image_name" --format="{{.Repository}}:{{.Tag}}"
}

function push_image {
    log_info "=== Pushing workflow image ==="
    
    local image_name="${args["image"]%:*}"
    local tag="${args["image"]#*:}"
    
    log_info "Pushing image: ${args["image"]}"

    if ! container_engine push "${args["image"]}"; then
        log_error "Failed to push image: ${args["image"]}"
        return 22
    fi
    log_success "Pushed: ${args["image"]}"

    # Push commit hash tag if available
    if ! git rev-parse --short=8 HEAD >/dev/null 2>&1; then
        log_warning "Failed to get git commit hash, skipping commit tag push"
    else
        local commit_hash
        commit_hash=$(git rev-parse --short=8 HEAD)
        local commit_tag="$image_name:$commit_hash"
        log_info "Pushing commit tag: $commit_tag"
        if ! container_engine push "$commit_tag"; then
            log_warning "Failed to push commit tag: $commit_tag"
        else
            log_success "Pushed: $commit_tag"
        fi
    fi

    # Push latest tag if not already latest
    if [[ "$tag" != "latest" ]]; then
        local latest_tag="$image_name:latest"
        log_info "Pushing latest tag: $latest_tag"
        if ! container_engine push "$latest_tag"; then
            log_warning "Failed to push latest tag: $latest_tag"
        else
            log_success "Pushed: $latest_tag"
        fi
    fi
    
    log_success "Image push completed successfully"
}

function deploy_manifests {
    log_info "=== Deploying manifests ==="
    
    if [[ ! -d "${args["manifests-directory"]}" ]]; then
        log_error "Manifests directory not found: ${args["manifests-directory"]}"
        return 23
    fi
    
    local manifest_files
    manifest_files=$(find "${args["manifests-directory"]}" -name "*.yaml" -o -name "*.yml" | wc -l)
    
    if [[ "$manifest_files" -eq 0 ]]; then
        log_error "No manifest files found in: ${args["manifests-directory"]}"
        return 24
    fi
    
    log_info "Found $manifest_files manifest file(s)"
    
    if [[ -n "${args["namespace"]:-}" ]]; then
        log_info "Applying manifests to namespace: ${args["namespace"]}"
        if ! kubectl apply -f "${args["manifests-directory"]}" -n "${args["namespace"]}"; then
            log_error "Failed to apply manifests to namespace: ${args["namespace"]}"
            return 25
        fi
    else
        log_info "Applying manifests to current namespace"
        if ! kubectl apply -f "${args["manifests-directory"]}"; then
            log_error "Failed to apply manifests"
            return 26
        fi
    fi
    
    log_success "Manifests deployed successfully"
}

# Main execution
function main {
    log_info "=== Starting workflow build process ==="
    
    parse_args "$@"
    
    check_dependencies
    
    gen_manifests
    
    build_image
    
    if [[ -n "${args["push"]}" ]]; then
        push_image
    fi
    
    if [[ -n "${args["deploy"]}" ]]; then
        deploy_manifests
    fi
    
    log_success "=== Workflow build process completed successfully ==="
}

# Run main function with all arguments
main "$@"
