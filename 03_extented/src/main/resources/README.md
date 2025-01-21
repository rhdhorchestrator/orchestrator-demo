# extendable-workflow workflow
The **Extendable Workflow** is a simple, dependency-free workflow designed to showcase the customization capabilities of the orchestrator's workflow execution form. Its input schema includes two custom properties: `CountryWidget` and `LanguageWidget`, which require custom plugins to load.

This workflow is intended to be used alongside the [Custom Form Example Plugin](https://github.com/rhdhorchestrator/custom-form-example-plugin/tree/main), which contains these custom widgets and additional validation features.

## Inputs:
The workflow input will include selecting the following parameters:
- First Name (string)
- Last Name (string)
- Country (CountryWidget)
- Password
- Password Confirmation 
- Language (LanguageWidget)

## Workflow diagram
![extendable-workflow workflow diagram](https://github.com/rhdhorchestrator/serverless-workflow-examples/blob/main/extendable-workflow/extendable-workflow.svg?raw=true)

## How to run

1. Use the Makefile and Dockerfile on the [serverless-workflow repository](https://github.com/rhdhorchestrator/serverless-workflows) to generate the workflow manifests and build the workflow image. 
2. Apply all manifests on the cluster, edit the sonataflow CR and insert the created image, and deploy the workflow. 
3. Add this [custom dynamic plugin](https://github.com/rhdhorchestrator/custom-form-example-plugin/tree/main) to the dynamic plugin config map, according to the readme instructions. 
4. Run the workflow through the UI or through the API. 

