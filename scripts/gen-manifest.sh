#!/bin/bash

# Always exit if a command fails
set -o errexit

program_name=$0

function usage {
    echo -e "Usage: WORKFLOW_ID=WORKFLOW_ID WORKFLOW_FOLDER=WORKFLOW_FOLDER WORKFLOW_IMAGE_REGISTRY=WORKFLOW_IMAGE_REGISTRY WORKFLOW_IMAGE_NAMESPACE=WORKFLOW_IMAGE_NAMESPACE [WORKFLOW_IMAGE_REPO=WORKFLOW_IMAGE_REPO] [WORKFLOW_IMAGE_TAG=WORKFLOW_IMAGE_TAG] [ENABLE_PERSISTENCE=true/false] $program_name"
    echo "  WORKFLOW_ID                   ID of the workflow to build and push"
    echo "  WORKFLOW_FOLDER               Path of the directory containing the workflow's files"
    echo "  WORKFLOW_IMAGE_REGISTRY       Registry name to which the image will be pushed. I.E: quay.io"
    echo "  WORKFLOW_IMAGE_NAMESPACE      Name of the registry's namespace in which to store the image. I.E: orchestrator"
    echo '  WORKFLOW_IMAGE_REPO           Name of the image, optional, default: demo-${WORKFLOW_ID}'
    echo "  WORKFLOW_IMAGE_TAG            Tag of the image, optional, default: latest"
    echo "  ENABLE_PERSISTENCE            Boolean indicating if persistence must be enabled, optional, default: true"
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

WORKFLOW_IMAGE_REPO="${WORKFLOW_IMAGE_REPO:-demo-${WORKFLOW_ID}}"
WORKFLOW_IMAGE_TAG="${WORKFLOW_IMAGE_TAG:-latest}"
ENABLE_PERSISTENCE="${ENABLE_PERSISTENCE:-true}"

# Check if Docker or Podman is installed
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

command -v kn-workflow
command -v kubectl

cd "${WORKFLOW_FOLDER}/src/main/resources"

echo -e "\nquarkus.flyway.migrate-at-start=true" >> application.properties

kn-workflow gen-manifest

# Enable bash's extended globbing for better pattern matching
shopt -s extglob
workflow_file=$(printf '%s\n' ./*.sw.y?(a)ml 2>/dev/null | head -n 1)
shopt -u extglob

if [ -z "$workflow_file" ]; then
  echo "No workflow file with .sw.yaml or .sw.yml suffix found."
  exit 1
fi

workflow_id=$(grep '^id:' "$workflow_file" | awk '{print $2}' | tr '[:upper:]' '[:lower:]')

if [ -z "$workflow_id" ]; then
  echo "No 'id' property found in the workflow file."
  exit 1
fi

find manifests/*.yaml -exec yq --inplace '.metadata.namespace = ""' {} \;

SONATAFLOW_CR=$(printf '%s' manifests/*-sonataflow_"${workflow_id}".yaml)
yq --inplace eval '.metadata.annotations["sonataflow.org/profile"] = "gitops"' "${SONATAFLOW_CR}"

yq --inplace ".spec.podTemplate.container.image=\"${WORKFLOW_IMAGE_REGISTRY}/${WORKFLOW_IMAGE_NAMESPACE}/${WORKFLOW_IMAGE_REPO}:${WORKFLOW_IMAGE_TAG}\"" "${SONATAFLOW_CR}"

if test -f "secret.properties"; then
  yq --inplace ".spec.podTemplate.container.envFrom=[{\"secretRef\": { \"name\": \"${workflow_id}-creds\"}}]" "${SONATAFLOW_CR}"
  kubectl create secret generic "${workflow_id}-creds" --from-env-file=secret.properties --dry-run=client -oyaml > "manifests/00-secret_${workflow_id}.yaml"
fi

if [ "${ENABLE_PERSISTENCE}" = true ]; then
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
              \"databaseSchema\": \"${WORKFLOW_ID}\"
            }
          }
        }
      }
    )" "${SONATAFLOW_CR}"
fi

echo "Manifests generated in ${WORKDIR}/${WORKFLOW_FOLDER}/src/main/resources/manifests"
