# Basic workflow
The basic workflow is a hello world kind of workflow: it send a notification and log into the console the input project name

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Environment variable  | Description | Mandatory | Default value |
|-----------------------|-------------|-----------|---------------|
| `BACKSTAGE_NOTIFICATIONS_URL`      | The backstage server URL for notifications | ✅ | |
| `NOTIFICATIONS_BEARER_TOKEN`      | The authorization bearer token to use to send notifications | ✅ | |


## Input
- `OCP project to create` [required] - the OCP project to be created on the OCP cluster.
- `Recipients` - the recipients of the notifications, automatically populated thanks to the custom UI plugin.

## Workflow diagram
![Basic diagram](src/main/resources/basic.svg)

## Installation

Use the scripts:
* Build and push the image:
```
./build-push.sh basic 01_basic
```
* Generate manifests that have to be applied on the OCP cluster wiht RHDH and OSL:
```
./gen-manifest.sh basic 01_basic
```
The manifests location will be displayed by the script.