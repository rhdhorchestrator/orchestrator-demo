# Basic workflow
The basic workflow is a hello world kind of workflow: it send a notification and log into the console the input project name

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable          | Description                                                 | Mandatory | Default value |
| ----------------------------- | ----------------------------------------------------------- | --------- | ------------- |
| `BACKSTAGE_NOTIFICATIONS_URL` | The backstage server URL for notifications                  | ✅         |               |
| `NOTIFICATIONS_BEARER_TOKEN`  | The authorization bearer token to use to send notifications | ✅         |               |


## Input
- `OCP project to create` [required] - the OCP project to be created on the OCP cluster.
- `Recipients` - the recipients of the notifications, automatically populated thanks to the custom UI plugin.

## Workflow diagram
![Basic diagram](src/main/resources/basic.svg)

## Installation

Use the scripts:
* Build and push the image:
```
cd ..
WORKFLOW_ID=basic WORKFLOW_FOLDER=01_basic WORKFLOW_IMAGE_REGISTRY=quay.io WORKFLOW_IMAGE_NAMESPACE=orchestrator ./scripts/build-push.sh
```
* Generate manifests that have to be applied on the OCP cluster wiht RHDH and OSL:
```
WORKFLOW_ID=basic WORKFLOW_FOLDER=01_basic WORKFLOW_IMAGE_REGISTRY=quay.io WORKFLOW_IMAGE_NAMESPACE=orchestrator ./scripts/gen-manifest.sh
```
The manifests location will be displayed by the script.

To apply the manifests, run:
```
TARGET_NS=sonataflow-infra
oc -n ${TARGET_NS} apply -f <path to manifests folder>/00-secret_*.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/02-configmap_*-props.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/01-sonataflow_*.yaml
```

Once the manifests are deployed, set the environements variables needed:
```
TARGET_NS=sonataflow-infra
WORKFLOW_NAME=basic
BACKSTAGE_NOTIFICATIONS_URL=http://backstage-backstage.rhdh-operator
oc -n ${TARGET_NS} patch secret "${WORKFLOW_NAME}-creds" --type merge -p '{"data": { "NOTIFICATIONS_BEARER_TOKEN": "'$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}')'"}}'

oc -n ${TARGET_NS} patch sonataflow "${WORKFLOW_NAME}" --type merge -p '{"spec": { "podTemplate": { "container": { "env": [{"name": "BACKSTAGE_NOTIFICATIONS_URL",  "value": "'${BACKSTAGE_NOTIFICATIONS_URL}'"}]}}}}'
```