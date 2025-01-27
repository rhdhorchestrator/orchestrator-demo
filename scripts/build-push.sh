#!/bin/bash
program_name=$0

function usage {
    echo -e "Usage: WORKFLOW_ID=WORKFLOW_ID WORKFLOW_FOLDER=WORKFLOW_FOLDER $program_name"
    echo "  WORKFLOW_ID                   ID of the workflow to build and push"
    echo "  WORKFLOW_FOLDER               Path of the directory containing the workflow's files"
    echo "  WORKFLOW_IMAGE_REGISTRY       Registry name to which the image will be pushed. I.E: quay.io"
    echo "  WORKFLOW_IMAGE_NAMESPACE      Name of the registry's namespace in which store the image. I.E: orchestrator"
    exit 1
}

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
  echo "Error: WORKFLOW_IMAGE_NAMESPACE env variable must be set with the name of the namespace's registry in which store the image; e.g: orchestrator"
  usage
fi

WORKDIR=$(mktemp -d)
echo "Workdir: ${WORKDIR}"

cp -r . ${WORKDIR}

cd "${WORKDIR}"

rm -rf **/target
mv ${WORKFLOW_FOLDER}/src/main/resources ${WORKFLOW_FOLDER}/.

IMAGE_NAME=${WORKFLOW_IMAGE_REGISTRY}/${WORKFLOW_IMAGE_NAMESPACE}/demo-${WORKFLOW_ID}
IMAGE_TAG=$(git rev-parse --short=8 HEAD)

docker build -f resources/workflow-builder.Dockerfile --build-arg WF_RESOURCES=${WORKFLOW_FOLDER} --ulimit nofile=4096:4096 --tag ${IMAGE_NAME}:${IMAGE_TAG} --tag ${IMAGE_NAME}:latest .
docker push ${IMAGE_NAME}:${IMAGE_TAG}
docker push ${IMAGE_NAME}:latest