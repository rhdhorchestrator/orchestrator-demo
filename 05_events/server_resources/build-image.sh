#!/bin/bash
program_name=$0

function usage {
    echo -e "Usage: IMAGE_REGISTRY=IMAGE_REGISTRY IMAGE_NAMESPACE=IMAGE_NAMESPACE $program_name"
    echo "  IMAGE_REGISTRY       Registry name to which the image will be pushed. I.E: quay.io"
    echo "  IMAGE_NAMESPACE      Name of the registry's namespace in which store the image. I.E: orchestrator"
    exit 1
}


if [[ -z "${IMAGE_REGISTRY}" ]]; then
  echo 'Error: IMAGE_REGISTRY env variable must be set with the image registry name; e.g: quay.io'
  usage
fi

if [[ -z "${IMAGE_NAMESPACE}" ]]; then
  echo "Error: IMAGE_NAMESPACE env variable must be set with the name of the namespace's registry in which store the image; e.g: orchestrator"
  usage
fi

IMAGE_NAME=${IMAGE_REGISTRY}/${IMAGE_NAMESPACE}/cloudevent-listener
IMAGE_TAG=$(git rev-parse --short=8 HEAD)

docker build --tag ${IMAGE_NAME}:${IMAGE_TAG} --tag ${IMAGE_NAME}:latest .
docker push ${IMAGE_NAME}:${IMAGE_TAG}
docker push ${IMAGE_NAME}:latest