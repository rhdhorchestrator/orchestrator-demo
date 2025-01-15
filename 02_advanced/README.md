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
- `Audit Jira Project Key` [required] - the Jira Project Key to which the workflow is configured to work and has permission to create and update and issue of type Task.
- `Operations Jira Project Key` [required] - the Jira Project Key to which the workflow is configured to work and has permission to create and update and issue of type Task.
- `OCP project to create` [required] - the OCP project to be created on the OCP cluster.
- `Recipients` - the recipients of the notifications, automatically populated thanks to the custom UI plugin.

## Workflow diagram
![Create OpenShift Project diagram](src/main/resources/create-ocp-project.svg)

## Installation


Use the scripts:
* Build and push the image:
```
WORKFLOW_ID=create-ocp-project  WORKFLOW_FOLDER=02_advanced ./scripts/build-push.sh
```
* Generate manifests that have to be applied on the OCP cluster wiht RHDH and OSL:
```
WORKFLOW_ID=create-ocp-project WORKFLOW_FOLDER=02_advanced WORKFLOW_IMAGE_REGISTRY=quay.io WORKFLOW_IMAGE_NAMESPACE=orchestrator ./scripts/gen-manifest.sh
```
The manifests location will be displayed by the script.

To apply the manifests, run:
```
TARGET_NS=sonataflow-infra
oc -n ${TARGET_NS} apply -f <path to manifests folder>/00-secret_*.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/02-configmap_*-props.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/01-configmap_*.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/01-sonataflow_*.yaml
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
oc -n $TARGET_NS patch secret "$WORKFLOW_NAME-creds" \
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
            name: create-ocp-project-creds
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