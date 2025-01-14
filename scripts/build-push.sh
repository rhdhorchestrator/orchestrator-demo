#!/bin/bash

WORKFLOW_ID=$1
WORKFLOW_FOLDER=$2

WORKDIR=$(mktemp -d)
echo "Workdir: ${WORKDIR}"

cp -r . ${WORKDIR}

cd "${WORKDIR}"

rm -rf **/target
mv ${WORKFLOW_FOLDER}/src/main/resources ${WORKFLOW_FOLDER}/.

IMAGE_NAME=quay.io/orchestrator/demo-${WORKFLOW_ID}
IMAGE_TAG=$(git rev-parse --short=8 HEAD)

docker build -f resources/workflow-builder.Dockerfile --build-arg WF_RESOURCES=${WORKFLOW_FOLDER} --ulimit nofile=4096:4096 --tag ${IMAGE_NAME}:${IMAGE_TAG} --tag ${IMAGE_NAME}:latest .
docker push ${IMAGE_NAME}:${IMAGE_TAG}
docker push ${IMAGE_NAME}:latest