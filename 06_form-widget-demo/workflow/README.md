# Dynamic Course Workflow

This directory contains a quarkus project that builds a serverless workflow that is used for the form widget demo.

To use the workflow, *you are not expected to build it from the source code*. Instead, please use the [Helm Chart](../dynamic-course-setup/Chart.yaml) provided to deploy all workflow resources and related demo resources.

## Building From Source

If you still wish to build a new image of the workflow project, or implement any changes in the workflow, you could do so using the installation steps provided below.

## Installation

To build the workflow image and push it to the image registry, use the [./scripts/build.sh](../../scripts/build.sh) script:
```bash
This script performs the following tasks in this specific order:
1. Generates a list of Operator manifests for a SonataFlow project using the kn-workflow plugin (requires at least v1.35.0)
2. Builds the workflow image using podman or docker
3. Optionally, deploys the application:
    - Pushes the workflow image to the container registry specified by the image path
    - Applies the generated manifests using kubectl in the current k8s namespace

Usage: 
    ./scripts/build.sh [flags]

Flags:
    -i|--image=<string> (required)       The full container image path to use for the workflow, e.g: quay.io/orchestrator/demo.
    -b|--builder-image=<string>          Overrides the image to use for building the workflow image.
    -r|--runtime-image=<string>          Overrides the image to use for running the workflow.
    -n|--namespace=<string>              The target namespace where the manifests will be applied. Default: current namespace.
    -m|--manifests-directory=<string>    The operator manifests will be generated inside the specified directory. Default: 'manifests' directory in the current directory.
    -w|--workflow-directory=<string>     Path to the directory containing the workflow's files (the 'src' directory). Default: current directory.
    -P|--no-persistence                  Skips adding persistence configuration to the sonataflow CR.
       --deploy                          Deploys the application.
    -h|--help                            Prints this help message.

Notes: 
    - This script respects the 'QUARKUS_EXTENSIONS' and 'MAVEN_ARGS_APPEND' environment variables.
```

1. Build the image and generate the manifests from workflow's directory (replace the target image):
```
../../scripts/build.sh --image=quay.io/orchestrator/dynamic-course-demo
```

The manifests location will be displayed by the script, or at the given location by the `--manifests-directory` flag
2. Push the image
```
POCKER=$(command -v podman || command -v docker) "$@"
$POCKER push <image>
```

3. Apply the manifests:
The generated manifests from the previous commands are included in this repository at `./workflow/manifests`.
```
TARGET_NS=sonataflow-infra
oc -n ${TARGET_NS} create -f .
```

All the previous steps can be done together by running:
```
../../scripts/build.sh --image=quay.io/orchestrator/dynamic-course-demo --deploy
```
