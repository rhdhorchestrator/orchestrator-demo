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
./build-push.sh create-ocp-project 02_advanced
```
* Generate manifests that have to be applied on the OCP cluster wiht RHDH and OSL:
```
./gen-manifest.sh create-ocp-project 02_advanced
```
The manifests location will be displayed by the script.