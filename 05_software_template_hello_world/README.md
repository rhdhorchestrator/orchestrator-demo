# Software Template Workflow

This project demonstrates how a Backstage software template can be used to invoke an Orchestrator workflow.  
To make the example more engaging, the Orchestrator workflow will launch the `hello-world` software template.

> **Note**: For simplicity, this workflow does not use the notifications plugin.  
> All execution results should be viewed directly in the **Orchestrator** plugin within RHDH.

## Prerequisites

- Red Hat Developer Hub (RHDH) version >= 1.6
- Orchestrator plugin version >= 1.6
- The `hello-world` software template must be registered in RHDH.  
  The template is located in: [`./hello-world-software-template`](./hello-world-software-template)

## Workflow Application Configuration

This workflow triggers a software template that creates a GitHub repository pre-populated with sample code.  
The following parameters must be provided as input:

- **GitHub Organization** – where the repository will be created
- **Repository Name** – name of the new repository
- **Service Name** – name of the service being created, used as the name of the component in RHDH
- **Component Owner** – user or team responsible for the component (e.g. user:default/guest)

Ensure these parameters are correctly supplied when executing the workflow via the Orchestrator plugin interface.

### Configuring Secrets
Before deployment, ensure the correct values are set in [00-secret_software-template-workflow-secrets.yaml](./workflow/manifests/00-secret_software-template-workflow-secrets.yaml)
You can update the `secret.properties` file before generating the manifests or modify the generated secret file directly.

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `RHDH_URL`      | The backstage server URL for notifications | ✅ | |
| `SCAFFOLDER_BEARER_TOKEN`      | The authorization bearer token to use to send notifications | ✅ | |


## Workflow diagram
![Workflow diagram](workflow/src/main/resources/workflow.svg)

## Installation
To install the workflow, apply the Kubernetes manifests located in the [`manifests`](./workflow/manifests/) directory.  
These manifests are ordered numerically to reflect their intended deployment sequence.

> **Note**: Before deploying, ensure the following prerequisites are satisfied:
> - The PostgreSQL secret references are correctly configured in the [SonataFlow Custom Resource](./workflow/manifests/04-sonataflow_software-template-workflow.yaml).
> - All required secrets are defined in the [Kubernetes Secret resource](./workflow/manifests/00-secret_software-template-workflow-secrets.yaml).

### Deploy the Workflow
```bash
oc apply -n sonataflow-infra -f ./workflow/manifests
```

### Verify the Deployment
To confirm the workflow was deployed successfully, run:
```bash
oc get sonataflow -n sonataflow-infra software-template-workflow
```

Expected output:
```
NAME                         PROFILE   VERSION   URL   READY   REASON
software-template-workflow   gitops    1.0             True
```

## Building the workflow and installing from built resources
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

1. Build the image and generate the manifests from workflow's directory (replace the target image):
```
../../scripts/build.sh --image=quay.io/orchestrator/demo-software-template-hello-world -w workflow
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
../../scripts/build.sh --image=quay.io/orchestrator/demo-software-template-hello-world --deploy
```

Once the manifests are deployed, set the environements variables needed.

### Add the Environment Variables to a Secret

Run the following command to update the Secret. Replace the example values with
the correct values for your environment:

```bash
export TARGET_NS='sonataflow-infra'
export WORKFLOW_NAME='software-template-workflow'

export SCAFFOLDER_BEARER_TOKEN=$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}' | base64 -d)
export RHDH_URL=http://backstage-backstage.rhdh-operator
```

Now, patch the Secret with these values:

```bash
oc -n $TARGET_NS patch secret "$WORKFLOW_NAME-secrets" \
  --type merge -p "{ \
    \"stringData\": { \
      \"SCAFFOLDER_BEARER_TOKEN\": \"$SCAFFOLDER_BEARER_TOKEN\",
      \"RHDH_URL\": \"$RHDH_URL\"
    }
  }"
```

After changing the secret, the workflow's pod must be restarted manually to ensure the values we set previsously in the secret are correctly applied:
```
oc -n $TARGET_NS scale deploy $WORKFLOW_NAME --replicas=0 && oc -n $TARGET_NS scale deploy $WORKFLOW_NAME --replicas=1
```

## Invoke the workflow from software template
Once you've practiced with the workflow and verified how it can be used to launch a software template and act upon its success/failure, you can explore the option of invoking a workflow from a software template.

For that purpose, import the software template from ./run-workflow-software-template/template.yaml into RHDH.
It takes the same amount of parameters as the workflow.

The software template was genearated by a [workflow-to-template converting template](https://github.com/rhdhorchestrator/workflow-software-templates/blob/v1.5.x/scaffolder-templates/github-workflows/convert-workflow-to-template/template.yaml).

## Demo
See [recording](https://youtu.be/pP9dhnstO6Q) of this example.
