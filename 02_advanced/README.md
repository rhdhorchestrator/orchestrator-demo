# Create OpenShift Project workflow
The Create OpenShift Project workflow is a workflow that demonstrates the following features of the serverless workflow technology:
* Integration with external service, in this case, Jira Cloud via its OpenAPI
* Polling
* Conditional branching
* Using the Notifications plugin to send notifications to the user

The workflow creates a Jira issue and waits for its approval within 60s.
After creating the Jira issue, the workflow sends a notification to the default user to be aware of the issue.
The workflow also creates another Jira issue for auditing purposes, to be closed after the workflow is done.

If the Jira issues for approval is resolved within 60 seconds, the workflow continues to the operations.
If the Jira issue isn't resolved within 60 seconds, the workflow fires a timeout event.

This workflow can be extended to introduce more capabilities, such as creating K8s resource in OpenShift cluster.

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `BACKSTAGE_NOTIFICATIONS_URL`      | The backstage server URL for notifications | ✅ | |
| `NOTIFICATIONS_BEARER_TOKEN`      | The authorization bearer token to use to send notifications | ✅ | |
| `JIRA_URL`      | The jira server URL | ✅ | |
| `JIRA_USERNAME`      | The jira username | ✅ | |
| `JIRA_API_TOKEN`      | The jira password | ✅ | |
| `OCP_API_SERVER_URL`      | The OCP API server url | ✅ | |
| `OCP_API_SERVER_TOKEN`      | The authorization bearer token to use when sending request to OCP | ✅ | |


## Input
- `Audit Jira Project Key` [required] - the Jira Project Key to which the workflow is configured to work and has permission to create and update and issue of type Task. This parameter is used to specify the Jira project for auditing the actions. It has no direct implication on the flow of the workflow; it is used to track the requests from the workflow. It must be created in Jira prior to the workflow's execution.
- `Operations Jira Project Key` [required] - the Jira Project Key to which the workflow is configured to work and has permission to create and update and issue of type Task. This parameter is used to specify the Jira project for approving the request of creating a new project in OpenShift. It is required to approve or deny the request for the workflow to continue. It must be created in Jira prior to the workflow's execution.
- `OCP project to create` [required] - the OCP project to be created on the OCP cluster.
- `Recipients` - the recipients of the notifications, automatically populated thanks to the custom UI plugin.

## Workflow diagram
![Create OpenShift Project diagram](src/main/resources/create-ocp-project.svg)

## Installation

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

1. Build the image and generate the manifests:
```
../scripts/build.sh --image=quay.io/orchestrator/demo-advanced
```

The manifests location will be displayed by the script.
2. Push the image
```
POCKER=$(command -v podman || command -v docker) "$@"
$POCKER push <image>
```

3. Apply the manifests:
```
TARGET_NS=sonataflow-infra
oc -n ${TARGET_NS} apply -f <path to manifests folder>/00-secret_*.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/02-configmap_*-props.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/01-configmap_*.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/01-sonataflow_*.yaml
```

All the previous steps can be done together by running:
```
../scripts/build.sh --image=quay.io/orchestrator/demo-advanced --deploy
```

Once the manifests are deployed, set the environements variables needed.

To obtain an OpenShift API token, create a Service Account, assign permissions to it, and request a token:

```bash
oc create sa orchestrator-ocp-api
oc adm policy add-cluster-role-to-user cluster-admin -z orchestrator-ocp-api

# Get the token for use in the next section
export OCP_API_SERVER_TOKEN=$(oc create token orchestrator-ocp-api)
```

### Add the Environment Variables to a Secret

Run the following command to update the Secret. Replace the example values with
the correct values for your environment:

```bash
export TARGET_NS='sonataflow-infra'
export WORKFLOW_NAME='create-ocp-project'

export NOTIFICATIONS_BEARER_TOKEN=$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}' | base64 -d)
export BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator

export JIRA_API_TOKEN='token_for_jira_api'
export JIRA_URL='https://replace-me.atlassian.net/'
export JIRA_USERNAME='foo@bar.com'

export OCP_API_SERVER_URL='https://api.cluster.replace-me.com:6443'
export OCP_API_SERVER_TOKEN=$(oc create token orchestrator-ocp-api)
```

Now, patch the Secret with these values:

```bash
oc -n $TARGET_NS patch secret "$WORKFLOW_NAME-secrets" \
  --type merge -p "{ \
    \"stringData\": { \
      \"NOTIFICATIONS_BEARER_TOKEN\": \"$NOTIFICATIONS_BEARER_TOKEN\",
      \"JIRA_API_TOKEN\": \"$JIRA_API_TOKEN\",
      \"OCP_API_SERVER_TOKEN\": \"$OCP_API_SERVER_TOKEN\",
      \"BACKSTAGE_NOTIFICATIONS_URL\": \"$BACKSTAGE_NOTIFICATIONS_URL\",
      \"JIRA_URL\": \"$JIRA_URL\",
      \"JIRA_USERNAME\": \"$JIRA_USERNAME\",
      \"OCP_API_SERVER_URL\": \"$OCP_API_SERVER_URL\"
    }
  }"
```

## Self-signed Certificate

Due to HTTPS self-signed certificates, we have to use a proxy to ignore the Java certification error when interacting the OCP API.
To do that, we deploy a proxy application that will forward the request (content and headers) to the OCP API:
```bash
oc -n $TARGET_NS apply -f resources/proxy.yaml
```

This deployment uses the `OCP_API_SERVER_URL` value of the secret to set its `TARGET_URL`.

### Update the Sonataflow CR to use Environment Variables
By defualt,the generated `Sonataflow` resource will load and set the environments variables from the secret:
```
  podTemplate:
    container:
      envFrom:
        - secretRef:
            name: create-ocp-project-secrets
```

In our case, we need to make sure the `OCP_API_SERVER_URL` points directly to the  `proxy-service` and not to the real `OCP_API_SERVER_URL` due to the certificates issue; the Sonataflow CR for the workflow must be updated
to use the correct value.
Use the following patch command to update the CR.
This will restart the Pod:

```bash
export TARGET_NS='sonataflow-infra'
export WORKFLOW_NAME='create-ocp-project'

oc -n $TARGET_NS patch sonataflow $WORKFLOW_NAME --type merge -p '{
  "spec": {
    "podTemplate": {
      "container": {
        "env": [
          {
            "name": "OCP_API_SERVER_URL",
            "value": "http://proxy-service"
          }
        ]
      }
    }
  }
}'
```

If there is no certificate issue, it is not needed to updated the `Sonataflow` CR. In such case, the pod must be restarted manually to ensure the values we set previsously in the secret are correctly applied:
```
oc -n $TARGET_NS scale deploy $WORKFLOW_NAME --replicas=0 && oc -n $TARGET_NS scale deploy $WORKFLOW_NAME --replicas=1
```
