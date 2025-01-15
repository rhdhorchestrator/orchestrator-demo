
# Orchestrator demo
This repository contains the source code of workflows we use for demo.

It also contains scripts used to build and push the image of the workflow and to generate the associated manifests in order to deploy the workflows in an OCP cluster.

## Pre-requisites
* having kn-workflow installed: see https://sonataflow.org/serverlessworkflow/main/testing-and-troubleshooting/kn-plugin-workflow-overview.html
  * You can find the binary here: https://mirror.openshift.com/pub/cgw/serverless-logic/latest/ 
* having an OCP cluster  with 
  * Red Hat Developer Hub (RHDH) v1.3 
    * Notification plugin 
    * Orchestrator plugin v1.3
  * OpenShift Serverless (OSL) v1.34

## Repository structure
* Folders starting with `0*_` are the folders containing the workflow quarkus projects
* The `resources` folder contains 
  * the Dockerfile used to build the workflow images 
  * a `Deployment` manifest to deploy a proxy application
  * a `Route` manifest to allow access to the DataIndex graphQL endpoint. Note that to access the route, we must delete the NetworkPolicies
* The `scripts` folder contains the scripts used to build and push the workflow image and to generate the manifests used to deploy the workflow.

## References

* How to deploy workflow in another namespace: https://github.com/rhdhorchestrator/orchestrator-helm-operator/tree/main/docs/release-1.3#additional-workflow-namespaces
* Developing workflow tutorials: https://redhat-scholars.github.io/serverless-workflow/osl/index.html
* Static token in RHDH/Backstage for the notification plugin: https://backstage.io/docs/auth/service-to-service-auth/#static-tokens
