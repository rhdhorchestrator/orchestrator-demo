# Events workflow
The events workflow is a hello world kind of workflow for eventing: it waits for an event and once it receives, it sends another one

## Workflow application configuration
Application properties can be initialized from environment variables before running the application: None

## Pre-requisites
When deploying on OCP cluster, [eventing communication](https://github.com/rhdhorchestrator/orchestrator-helm-operator/blob/main/docs/release-1.4/eventing-communication/README.md) must be enabled.

> [!NOTE]
> Currently this workflow is only usable when deployed on a cluster with
> * RHDH
> * Orchestrator plugin 
> * Serverless Logic (Sonataflow) operator
> * Serverless (Knative) operator
> The docker-compose folder may be used to locally deploy Kafka and PSQL but the produced event will not be processed by the server producing/listening for cloudevents, see https://github.com/apache/incubator-kie-kogito-examples/tree/main/serverless-workflow-examples/serverless-workflow-callback-quarkus for more information


## Input
No needed input

## Workflow diagram
![events diagram](src/main/resources/events.svg)

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

Use the scripts:
1. Build the image and generate the manifests:
```
../scripts/build.sh --image=quay.io/orchestrator/demo-eventing -n sonataflow-infra
```

The manifests location will be displayed by the script.
2. Push the image
```
docker push <image>
```

3. Apply the manifests:
```
TARGET_NS=sonataflow-infra
oc -n ${TARGET_NS} apply -f <path to manifests folder>/00-secret_*.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/02-configmap_*-props.yaml
oc -n ${TARGET_NS} apply -f <path to manifests folder>/01-sonataflow_*.yaml
```

All the previous steps can be done together by running:
```
../scripts/build.sh --image=quay.io/orchestrator/demo-eventing -n sonataflow-infra --deploy
```


Then deploy the server producing and listening for cloudevents:
```
oc -n ${TARGET_NS} apply -f 05_events/server_resources/deployment.yaml
```

> [!NOTE]
> This deployment uses our image, if you want to rebuild your own, execute 05_events/server_resources/build-image.sh

When eventing communication is enabled, the Serverless Logic operator will create the resources needed for the workflow to work:
* `sinkbinding`: they will injec the `K_SINK` value into the workflow deployment with the broker URL value
* `trigger`: they will route the cloudevents to the workflow. Only events consumed by the workflow will have a trigger resource created.

For events produced by the workflow, a `trigger` must be created so the cloudevent will be routed to the application consuming this event. 
Execute the following to create the trigger for the cloudevent server:
```
oc -n ${TARGET_NS} apply -f 05_events/knative_resources/trigger.yaml
```
Note that the trigger and the broker must be in the same namespace.

Now to trigger the workflow, from within the `cloudevent-listener` pod, send a `POST` request to the server:
```
BROKER_URL=$(oc -n ${TARGET_NS} get broker -o yaml | yq -r .items[0].status.address.url)
curl -XPOST "http://cloudevent-listener-svc/trigger?source=manual&type=wait&broker_url=${BROKER_URL}"
```
You can also expose a route for the `cloudevent-listener` so you can trigger the event from outside the pod.

`BROKER_URL` is populated with a command assuming the broker is in the same namespace as the workflow. If that is not the case, update the command with your value. 
> [!WARNING]
> The `sontaflow-infra ` namespace has `NetworkPolicies` in place to prevent access from unknown/unauthorized namespace/pods. If the broker is not in the same namespace as the workflow, you may need to add a new `NetworkPolicy` to allow access from the broker's namespace.