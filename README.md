
# Orchestrator demo
This repository contains the source code of workflows we use for demo.

It also contains scripts used to build and push the image of the workflow and to generate the associated manifests in order to deploy the workflows in an OCP cluster.

## Pre-requisites
* Having `kn-workflow` **v1.34** installed: see https://docs.openshift.com/serverless/1.34/serverless-logic/serverless-logic-getting-started/serverless-logic-creating-managing-workflows.html
  * You can find the binary here: https://mirror.openshift.com/pub/cgw/serverless-logic/1.34.0/
* Having an OCP cluster  with 
  * Red Hat Developer Hub (RHDH) v1.3 
    * Notification plugin 
    * Orchestrator plugin v1.3: https://github.com/rhdhorchestrator/orchestrator-helm-operator/tree/main/docs/release-1.3
  * OpenShift Serverless (OSL) v1.34

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

## References

* How to deploy workflow in another namespace: https://github.com/rhdhorchestrator/orchestrator-helm-operator/tree/main/docs/release-1.3#additional-workflow-namespaces
* Developing workflow tutorials: https://redhat-scholars.github.io/serverless-workflow/osl/index.html
* OpenShift Serverless Logic: https://openshift-knative.github.io/docs/docs/latest/serverless-logic/about.html
* Using Quarkus: https://docs.redhat.com/en/documentation/red_hat_build_of_quarkus/3.15/html/getting_started_with_red_hat_build_of_quarkus/assembly_quarkus-getting-started_quarkus-getting-started#proc_online-maven_quarkus-getting-started
Static token in RHDH/Backstage for the notification plugin: https://backstage.io/docs/auth/service-to-service-auth/#static-tokens
* RHDH configuration if running behind a proxy: https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/html/configuring/running-behind-a-proxy#running-behind-a-proxy 