
# Orchestrator demo
This repository contains the source code of workflows we use for demo.

It also contains scripts used to build and push the image of the workflow and to generate the associated manifests in order to deploy the workflows in an OCP cluster.

## Pre-requisites
* Having `kn-workflow` **v1.36** installed: see https://docs.openshift.com/serverless/1.36/serverless-logic/serverless-logic-getting-started/serverless-logic-creating-managing-workflows.html
  * You can find the binary here: https://mirror.openshift.com/pub/cgw/serverless-logic/1.36.0/
* Having an OCP cluster  with 
  * Red Hat Developer Hub (RHDH) v1.5 or v1.6 
    * Notification plugin 
    * Orchestrator plugin [v1.5](https://www.rhdhorchestrator.io/1.5/docs/) or [v1.6](https://www.rhdhorchestrator.io/1.6/docs/)
  * OpenShift Serverless (OSL) v1.36

> **Notice**: The content of this repository was tested on Fedora/RHEL. Building images on MacOS with podman fails, but can be completed with docker.

## Repository structure
* Folders starting with `0*_` are the folders containing the workflow projects in Quarkus layout
* The `resources` folder contains 
  * the Dockerfile used to build the workflow images 
  * a `Deployment` manifest to deploy a proxy application
  * a `Route` manifest to allow access to the DataIndex graphQL endpoint. Note that to access the route, we must delete the NetworkPolicies
* The `scripts` folder contains the scripts used to build and push the workflow image and to generate the manifests used to deploy the workflow.

## Getting started
The workflows projects were create using the `kn-workflow` cli by running:
```bash
kn-workflow quarkus create --name <specify project name, e.g. 00_new_project>
```

Edit the workflow, add schema and spec files and run it locally from project's folder with:
```bash
kn-workflow quarkus run
```
## Workflow images
For running the workflow locally (with `kn-workflow run`), the following image is pulled:
```
registry.redhat.io/openshift-serverless-1/logic-swf-devmode-rhel8:1.36.0
```

For building the workflow image, the following images are pulled:
```
registry.redhat.io/openshift-serverless-1/logic-swf-builder-rhel8:1.36.0-8
registry.access.redhat.com/ubi9/openjdk-17:1.21-2
```

## References

* How to deploy workflow in another namespace: https://github.com/rhdhorchestrator/orchestrator-go-operator/tree/main/docs/release-1.6#additional-workflow-namespaces
* Developing workflow tutorials: https://redhat-scholars.github.io/serverless-workflow/osl/index.html
* OpenShift Serverless Logic: https://openshift-knative.github.io/docs/docs/latest/serverless-logic/about.html
* Using Quarkus: https://docs.redhat.com/en/documentation/red_hat_build_of_quarkus/3.15/html/getting_started_with_red_hat_build_of_quarkus/assembly_quarkus-getting-started_quarkus-getting-started#proc_online-maven_quarkus-getting-started
Static token in RHDH/Backstage for the notification plugin: https://backstage.io/docs/auth/service-to-service-auth/#static-tokens
* RHDH configuration if running behind a proxy: https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/html/configuring/running-behind-a-proxy#running-behind-a-proxy 
