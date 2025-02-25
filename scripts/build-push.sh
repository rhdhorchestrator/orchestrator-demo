#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status.

program_name=$0

function usage {
    echo -e "Usage: WORKFLOW_ID=WORKFLOW_ID WORKFLOW_FOLDER=WORKFLOW_FOLDER $program_name"
    echo "  WORKFLOW_ID                   ID of the workflow to build and push"
    echo "  WORKFLOW_FOLDER               Path of the directory containing the workflow's files"
    echo "  WORKFLOW_IMAGE_REGISTRY       Registry name to which the image will be pushed. I.E: quay.io"
    echo "  WORKFLOW_IMAGE_NAMESPACE      Name of the registry's namespace in which to store the image. I.E: orchestrator"
    exit 1
}

# Validate required environment variables
if [[ -z "${WORKFLOW_ID}" ]]; then
  echo 'Error: WORKFLOW_ID env variable must be set with the ID of the workflow to build and push; e.g: create-ocp-project'
  usage
fi

if [[ -z "${WORKFLOW_FOLDER}" ]]; then
  echo "Error: WORKFLOW_FOLDER env variable must be set to the path of the directory containing the workflow's files; e.g: 02_advanced"
  usage
fi

if [[ -z "${WORKFLOW_IMAGE_REGISTRY}" ]]; then
  echo 'Error: WORKFLOW_IMAGE_REGISTRY env variable must be set with the image registry name; e.g: quay.io'
  usage
fi

if [[ -z "${WORKFLOW_IMAGE_NAMESPACE}" ]]; then
  echo "Error: WORKFLOW_IMAGE_NAMESPACE env variable must be set with the name of the namespace's registry in which to store the image; e.g: orchestrator"
  usage
fi

# Check if docker or podman is installed
DOCKER_AVAILABLE=false
PODMAN_AVAILABLE=false

if command -v docker &>/dev/null; then
    DOCKER_AVAILABLE=true
fi

if command -v podman &>/dev/null; then
    PODMAN_AVAILABLE=true
fi

# Interactive prompt for choosing container CLI
if $DOCKER_AVAILABLE && $PODMAN_AVAILABLE; then
    echo "Both Docker and Podman are available."
    read -p "Would you like to use Docker or Podman? (default: Docker) [d/p]: " choice
    if [[ "$choice" =~ ^[Pp]$ ]]; then
        CONTAINER_CLI="podman"
    else
        CONTAINER_CLI="docker"
    fi
elif $DOCKER_AVAILABLE; then
    echo "Docker is available. Using Docker."
    CONTAINER_CLI="docker"
elif $PODMAN_AVAILABLE; then
    echo "Docker is not available, but Podman is. Using Podman."
    CONTAINER_CLI="podman"
else
    echo "Error: Neither Docker nor Podman is installed."
    exit 1
fi

echo "Using container CLI: $CONTAINER_CLI"

# Check authentication for Red Hat registry if using Podman
if [[ "$CONTAINER_CLI" == "podman" ]]; then
    if ! podman login --get-login registry.redhat.io &>/dev/null; then
        echo "Not logged into registry.redhat.io. Logging in..."
        podman login registry.redhat.io
    fi
fi

WORKDIR=$(mktemp -d)
echo "Workdir: ${WORKDIR}"

cp -r . "${WORKDIR}"

cd "${WORKDIR}"

rm -rf **/target
mv ${WORKFLOW_FOLDER}/src/main/resources ${WORKFLOW_FOLDER}/.

IMAGE_NAME=${WORKFLOW_IMAGE_REGISTRY}/${WORKFLOW_IMAGE_NAMESPACE}/demo-${WORKFLOW_ID}
IMAGE_TAG=$(git rev-parse --short=8 HEAD)

# Build the container image with additional build arguments
$CONTAINER_CLI build -f resources/workflow-builder.Dockerfile \
  --build-arg WF_RESOURCES=${WORKFLOW_FOLDER} \
  --build-arg FLOW_NAME="${WORKFLOW_ID}" \
  --build-arg FLOW_SUMMARY="Summary of ${WORKFLOW_ID}" \
  --build-arg FLOW_DESCRIPTION="Description of ${WORKFLOW_ID}" \
  --ulimit nofile=4096:4096 \
  --tag ${IMAGE_NAME}:${IMAGE_TAG} \
  --tag ${IMAGE_NAME}:latest .

# Push the image
$CONTAINER_CLI push ${IMAGE_NAME}:${IMAGE_TAG}
$CONTAINER_CLI push ${IMAGE_NAME}:latest
