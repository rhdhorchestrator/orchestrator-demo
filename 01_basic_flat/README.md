# Basic workflow - flat version
The basic workflow is a hello world kind of workflow: it log a message into the console the input project name.
This version as a flat or non-quarkus layout, hence we are not demonstrating the usage of custom java class.

## Input
- `OCP project to create` [required] - the OCP project to be created on the OCP cluster.
- `Recipients` - the recipients of the notifications, automatically populated thanks to the custom UI plugin.

## Workflow diagram
![Basic diagram](src/main/resources/basic-flat.svg)

## Installation
To install the workflow, apply the Kubernetes manifests located in the [`manifests`](./manifests/) directory.  
These manifests are organized and numbered according to their required deployment order.

> **Note**: Before applying the manifests, ensure the PostgreSQL secret references are correctly configured in the [SonataFlow Custom Resource](./manifests/03-sonataflow_basic-flat.yaml).

### Deploy the Workflow

```bash
oc apply -n sonataflow-infra -f ./01_basic_flat/manifests
```

### Verify the Deployment
To confirm the workflow was deployed successfully, run:
```bash
oc get sonataflow -n sonataflow-infra basic-flat
```

Expected output:
```
NAME    PROFILE   VERSION   URL   READY   REASON
basic-flat   gitops    1.0             True
```

## Building the workflow
Sometimes a workflow may need to be modified—for example, to fix a bug or introduce new functionality. In such cases, it must be rebuilt.
To build the workflow image and push it to the image registry, use the [./scripts/build.sh](../scripts/build.sh) script:
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

Use the scripts:
1. Build the image and generate the manifests:
```
../scripts/build.sh --image=quay.io/orchestrator/demo-basic-flat
```

The manifests location will be displayed by the script.
2. Push the image
```bash
POCKER=$(command -v podman || command -v docker) "$@"
$POCKER push <image>
```

3. Apply the manifests:
```bash
TARGET_NS=sonataflow-infra
oc -n ${TARGET_NS} apply -f <path to manifests folder>/00-secret_*.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/02-configmap_*-props.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/01-sonataflow_*.yaml
```

All the previous steps can be done together by running:
```bash
../scripts/build.sh --image=quay.io/orchestrator/demo-basic-flat --deploy -S
```
