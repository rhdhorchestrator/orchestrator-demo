# Custom UI widgets extending the execution form 
This demo shows how to extend the workflow execution form for custom-developed UI widgets (components) using React/Typescript to either customize look&feel, perform data retrieval, do validations, handle simple business logic or provide context-awareness among form components.

The set of input parameters for a workflow execution is defined by the [JSON Schema](https://json-schema.org/understanding-json-schema/reference) which is referenced from the workflow definition via `dataInputSchema` property.
Later on, the UI leverages the [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form) to compose the UI form conforming the requested input JSON schema.

Using following capability, the common data types can be extended for any TypeScript/React components.

## Sample workflow
For the purpose of the demonstration, a simple [workflow](./src/main/resources/extendable-workflow.sw.yaml) has been created.
Its scope is intentionally kept at bare minimum, to demonstrate the flow.

### Prerequisites
Next steps expect having the OCP, RHDH and the Orchestrator deployed along this sample `extendable_workflow` - refer to the previous 01_basic and 02_advanced topics and use the workflow from this folder.

### Orientation
Once having the `extendable_workflow` deployed, its execution will fail for the beginning. As expected for now.

Before we "fix" that by deploying the referenced custom components, let's mark the interesting extension points from the workflow perspective.

The [workflow](./src/main/resources/extendable-workflow.sw.yaml) defines its input parameters via:
```yaml
dataInputSchema: "schemas/extendable-workflow.sw.input-schema.json"
```

The schema contains definition of the input parameters structure and conforms the [JSON Schema](https://json-schema.org/understanding-json-schema/reference), as explained in the previous demo topics.

The new addition is the `ui:widget` and the way how to provide a custom set of non-standard widgets (on top of the existing [widget library](https://rjsf-team.github.io/react-jsonschema-form/docs/usage/widgets/)).

```json
        "country": {
          "type": "string",
          "title": "Country",
          "ui:widget": "CountryWidget"
        },
```

This `ui:widget` reference is all what is needed in the schema to let the Orchestrator UI render a custom-developed `CountryWidget` component to supply the `country` input parameter.

The next chapter is focused on the development and deployment of such `CountryWidget` component.

## Custom widget development
The react-jsonschema-form custom React/TypeScript widgets (components) referenceable from the `dataInputSchema` are deployed to the RHDH/Orchestrator via a custom-developed Backstage frontend plugin. 

Such frontend plugin is of the common [Backstage architecture](https://backstage.io/docs/plugins/structure-of-a-plugin) structure and its purpose is to **export API** providing the custom widgets in the form of a [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form)-component decorator.

The API implementation needs to be referenced via `orchestratorFormApiRef` and it needs to implement the `OrchestratorFormApi` TypeScript interface (from the `@red-hat-developer-hub/backstage-plugin-orchestrator-form-api` NPM dependency).

For the purpose of deployment of the plugin to the RHDH, it needs to be converted to a dynamic plugin as described in the [RHDH dynamic plugins development](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/#Extend).

An example is provided in the [custom-form-example-plugin](./custom-form-example-plugin/plugins/custom-form-example-plugin).

## Developer flow
From the nature of the task, the development is in the React/TypeScript.

The produced artifact is an RHDH frontend dynamic plugin exporting the requested Backstage API implementation.

To boost productivity, it is recommended to develop the API or components in isolation (locally) and deploying the dynamic plugin for final testing in the OCP cluster with RHDH.

### Dev-only Backstage instance
To enable isolated local development, a single-purpose Backstage instance is [created](./custom-form-example-plugin) by following [Backstage documentation](https://backstage.io/docs/getting-started/#1-create-your-backstage-app).

Subsequently, a frontend plugin exporting the `OrchestratorFormApi` implementation is created under the `plugins` folder and added to the frontend `packages/app` in the [App.tsx](03_extendable_form/custom-form-example-plugin/packages/app/src/App.tsx).

In other words, we use upstream Backstage with a static frontend plugin for development.

Once developed and tested, we convert such plugin to a dynamic one and deploy it to the RHDH.

### Dev setup run
When in the [custom-form-example-plugin](./custom-form-example-plugin) root folder, issue

```bash
yarn install
yarn dev
```

And navigate to [http://localhost:3000/](http://localhost:3000/). In the left-side menu is a the new plugin as registered through the `packages/app` in the [App.tsx](./custom-form-example-plugin/packages/app/src/App.tsx).

Same as the whole Backstage instance, **this page is for the widget development only** and is not part of the resulting plugin.

### FE plugin with custom extensions
The plugin entry point: [custom-form-example-plugin/plugins/custom-form-example-plugin/src/plugin.ts](./custom-form-example-plugin/plugins/custom-form-example-plugin/src/plugin.ts).
That plugin is of a common Backstage structure, but mind the use of `orchestratorFormApiRef` reference as we are providing implementation of the API, the `factory` method which returns the implementation and the way how dependencies on other Backstage services can be delivered into our new API.

The `CustomApi.getFormDecorator()` provides decorator for the [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form) which is used/called in the Orchestrator UI to render the form.

Mind following line:
```js
          <FormComponent
            widgets={widgets}
```

This is the root functionality of the whole extension - supplying custom widgets to the RJSF Form.

By leveraging this principle, we can decorate functionality of the form for other features, like error handling.

### Passing configuration
The Backstage keeps configuration in the `app-config.yaml`, supported by the `dynamic-plugins.yaml` in the context of the RHDH.

When deployed in the OCP, those config files are maintained via ConfigMaps in the target namespace of the Backstage CR.

The administrator can provide various configuration props by modifying these files and ConfigMaps to make them available for the `OrchestratorFormApi` implementation.

Please see the use of the `configApi` Backstage service (an injected dependency to our plugin) and the `config.d.ts` file for an example. Check Backstage [documentation](https://backstage.io/docs/conf/reading) for more details.

The configuration can include URLs to external systems or secrets which are passed as environment variables to the Backstage pod.

## Form context
The widget components are optionally provided with the form context - initial or progress values of other fields.
Those can be used for tweaking subsequent validations, requests or visual aspects.

### Release
To build the plugin:

```bash
cd ./custom-form-example-plugin/plugins/custom-form-example-plugin
yarn install
yarn build
yarn export-dynamic
```

Maintain the version in the `package.json` accordingly.

These steps will result in building and converting the sources into a dynamic plugin and can be repeated whenever needed.

Based on the deployment needs, this dynamic plugin can be published to an NPM registry (public or private):

```bash
yarn publish
```

In fact, the publish-step is not needed, it just might be helpful way in making the NPM package .tgz file accessible via HTTP at the start-up time of the Backstage OCP pod.

To get the .tgz and integrity checksum from NPM registry once published:

```bash
npm view custom-form-example-plugin@0.4.0

...
.tarball: https://registry.npmjs.org/custom-form-example-plugin/-/custom-form-example-plugin-0.4.0.tgz
.shasum: 4096d3728dc8cd039833e9cf736a54fcb0064ac0
.integrity: sha512-r6gt4Wrc0AaMqbag494NZDC0kkMjyXOnZZn/it05Lpf5/mJ8463DoAnEKbRIYcIJm8uQzmTLe9ctnExJbdWG2g==
...
```

Or without NPM registry:

```bash
cd plugins/custom-form-example-plugin
yarn pack 
shasum -b -a 512 custom-form-example-plugin-v0.4.0.tgz | awk '{ print $1 }' | xxd -r -p | base64 | awk '{ printf("%s", $0) }' | awk '{print "sha512-"$0}' ; 
```

### Deployment
Once the dynamic plugin is exposed (either NPM registry or an HTTP server), we can add reference to it into RHDH `dynamic-plugins-rhdh` ConfigMap:

```yaml
data:
  dynamic-plugins.yaml: |
    includes:
      - dynamic-plugins.default.yaml
    plugins:
      - disabled: false
        package: "https://registry.npmjs.org/custom-form-example-plugin/-/custom-form-example-plugin-0.4.0.tgz"
        integrity: sha512-r6gt4Wrc0AaMqbag494NZDC0kkMjyXOnZZn/it05Lpf5/mJ8463DoAnEKbRIYcIJm8uQzmTLe9ctnExJbdWG2g==
        pluginConfig:
          dynamicPlugins:
            frontend:
              custom-form-example-plugin:
                countriesUrl: https://restcountries.com/v3.1/all
```

And wait till the the operator restarts the pod.

Watch the `backstage-backstage-xxxx` pod logs for potential errors, same as the browser console.
The init container of this pod is responsible for downloading and installing the dynamic plugin packages, errors are reported in its logs.

## Accessing external services
Per description above, the `OrchestratorFormApi` is solemnly frontend code, meaning it is executed in the browser.

Using common Backstage APIs, the widgets can retrieve data from the Backstage services or call the Backstage API.
An example of receiving two of the Backstage APIs is in the [example plugin](./custom-form-example-plugin/plugins/custom-form-example-plugin/src/plugin.ts).

Access to 3rd party external services (like the OpenShift API) might be affected by either network or CORS limitations.
To address these issues, a Backstage backend plugin exposing new REST endpoints can be implemented to act as a proxy or pre-processor for big data sets.
This is out of scope for this demo, we refer to the Backstage documentation for additional details.

## Limitations
- Frontend - huge data sets, CORS or network limitations
  - to access 3rd party APIs or pre-processing large datasets, yet another backend plugin exposing new Backstage REST API endpoints should be considered

- Requires TypeScript/React coding skills. Can not be handled declaratively.

- Single `OrchestratorFormApi` implementation per RHDH deployment
  - widgets for all workflows are supplied via a single plugin, development coordination and development standards are needed

## More info
- [Orchestrator Extensible Form](https://github.com/redhat-developer/rhdh-plugins/blob/main/workspaces/orchestrator/docs/extensibleForm.md)
- [Backstage plugin development](https://backstage.io/docs/plugins/structure-of-a-plugin)
- [RHDH dynamic plugins development](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/#Extend)
- [JSON Schema](https://json-schema.org/understanding-json-schema/reference)
- [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form)