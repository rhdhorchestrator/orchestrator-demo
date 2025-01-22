# Custom Form Plugin Example

This repository demonstrates a Backstage plugin that customizes and extends the orchestrator workflow execution form. It provides a standalone Backstage instance for testing and debugging the plugin before integration with the orchestrator in a Red Hat Developer Hub (RHDH) deployment. The plugin’s features are illustrated using an [example workflow](https://github.com/parodos-dev/serverless-workflows-config/tree/main/charts/extendable-workflow). This workflow’s input schema includes custom UI properties that trigger specific form enhancements, such as the property ["ui:widget": "CountryWidget"](https://github.com/parodos-dev/serverless-workflows-config/blob/main/charts/extendable-workflow/templates/02-configmap_01-extendable-workflow-resources-schemas.yaml#L24), which loads the plugin's custom `CountryWidget` component.

## Getting Started

### To Run the Plugin Locally:

#### 1. Install Dependencies:

```bash
yarn install
```

#### 2. Run the Application:

```bash
yarn dev
```

#### 3. Access the Custom Form:

Open your browser and go to http://localhost:3000. In the navigation panel, select Custom Form to explore the extended workflow execution form in action.

### To run the plugin on RHDH deployment

#### 1. Install the example workflow:

Follow [these instructions](https://github.com/parodos-dev/serverless-workflows-config/blob/main/docs/main/extendable-workflow/README.md#persistence-pre-requisites) to install the workflow.

> **Note:** when running the workflow without the plugin installed, the form will throw errors.

#### 2. Configure RHDH to load the plugin

Add the following entry to the [RHDH plugins ConfigMap](https://docs.redhat.com/fr/documentation/red_hat_developer_hub/1.3/html/installing_and_viewing_dynamic_plugins/proc-config-dynamic-plugins-rhdh-operator_title-plugins-rhdh-about):

```yaml
- disabled: false
  package: 'https://github.com/parodos-dev/custom-form-example-plugin/releases/download/0.2.0/custom-form-example-plugin-0.2.0.tgz'
  integrity: sha512-1L2JKfvJBYHXFQsb6NrgvdXUrAXkmlloDAQiTeR8La2cNqOTeBMF91E+0ixhm4wy10gzdZXtytORjk1UWFVHlw==
  pluginConfig:
    dynamicPlugins:
      frontend:
        custom-form-example-plugin:
          countriesUrl: https://restcountries.com/v3.1/all
```

#### 3. Access the Custom Form:

Access the Custom Form: Open RHDH in your browser. Navigate to the Orchestrator and run the workflow titled Extendable workflow.

## Observing the Custom Features

1. **Custom Widgets**

   - The **Country** field dropdown is customized to fetch country data from the public API: [https://restcountries.com/v3.1/all](https://restcountries.com/v3.1/all).
   - In the second step, observe the custom dropdown for the **Language** field.

2. **Custom Inter-field Validation**

   - Enter mismatching passwords and click **Next** to see the error message: `".personalInfo.password passwords do not match."`

3. **Custom Async Validation**

   - Custom asynchronous validation occurs after all other validations pass and **Next** is clicked.
   - Fill in all required fields correctly, then enter "admin" as the **First name** and click **Next**. A message will appear: `"firstName Name admin is reserved"`. Notice the **Next** button is temporarily in a busy state as async validation runs.

4. **Custom Inter-field Dependencies**
   - Complete the form’s first step and click **Next**. The **Language** dropdown will display a language relevant to the selected country.

> **Note:** This example is specific to a single workflow. Since only one plugin like this can be provided, a generic implementation is recommended to support all workflows. For example, using a property like `ui:validationType` can allow the plugin to provide custom validations for various `validationType` values.

More details on the architecture are available [here](https://github.com/redhat-developer/rhdh-plugins/blob/main/workspaces/orchestrator/plugins/orchestrator/docs/extensibleForm.md).
