
# Orchestrator demo
This repository contains the source code of workflows we use for demo.

It also contains scripts used to build and push the image of the workflow and to generate the associated manifests in order to deploy the workflows in an OCP cluster.

## Pre-requisites
* having kn-workflow installed: see https://sonataflow.org/serverlessworkflow/main/testing-and-troubleshooting/kn-plugin-workflow-overview.html
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