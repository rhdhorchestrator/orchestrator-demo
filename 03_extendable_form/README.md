# Custom UI widgets extending the execution form 
This demo shows how to extend the workflow execution form for custom-developed UI widgets (components) using React/Typescript to either customize look&feel, perform data retrieval, do validations, handle simple business logic or provide context-awareness among form components.

The set of input parameters for a workflow execution is defined by [JSON Schema](https://json-schema.org/understanding-json-schema/reference) which is referenced from the workflow definition via `dataInputSchema` property.
Later on, the UI leverages the [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form) to compose the UI form conforming the requested input JSON schema.

Using following capability, the common data types can be extended for any TypeScript/React components.

## Sample workflow
For the purpose of the demonstration, a simple [workflow](./src/main/resources/extendable-workflow.sw.yaml) has been created.
It's scope is intentionally kept at bare minimum, to demonstrate the flow.

### Prerequisites
Farther steps expect having the OCP, RHDH and the Orchestrator deployed along this sample `extendable_workflow` - refer to the previous 01_basic and 02_advanced topics.

### Orientation
Once having the `extendable_workflow` deployed, it's execution will fail for the beginning.
Before we "fix" that by deploying the referenced custom components, let's mark the extension points from the workflow perspective.

The [workflow](./src/main/resources/extendable-workflow.sw.yaml) defines its input parameters via:
```yaml
dataInputSchema: "schemas/extendable-workflow.sw.input-schema.json"
```

The schema contains definition of the input parameters structure and conforms the [JSON Schema](https://json-schema.org/understanding-json-schema/reference), as explained in the previous demo topics.

What is new is the use of `ui:widget` and the way how to provide custom set of non-standard widgets (on top of existing [widget library](https://rjsf-team.github.io/react-jsonschema-form/docs/usage/widgets/)).

```json
        "country": {
          "type": "string",
          "title": "Country",
          "ui:widget": "CountryWidget"
        },
```

This reference is all what is needed in the schema to use to let the Orchestrator UI render a custom-developed `CountryWidget` component to supply the `country` input parameter.

The next chapter is focused on the development and deployment of such a component.

## Custom widget development
The react-jsonschema-form custom React/TypeScript widgets (components) referenceable from the `dataInputSchema` are deployed to the RHDH/Orchestrator via a custom-developed Backstage frontend plugin. 

Such frontend plugin is of the common [Backstage architecture](https://backstage.io/docs/plugins/structure-of-a-plugin) structure and its purpose is to **export API** providing the custom widgets in the form of a [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form)-component decorator.

The API implementation needs to be of `orchestratorFormApiRef` ID and it needs to implement the `OrchestratorFormApi` TypeScript interface (from the `@red-hat-developer-hub/backstage-plugin-orchestrator-form-api` NPM dependency).

For the purpose of deployment of the plugin to the RHDH, it needs to be converted to a dynamic plugin as described in the [RHDH dynamic plugins development](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/#Extend).

An example is provided in the [custom-form-example-plugin](./custom-form-example-plugin/plugins/custom-form-example-plugin).

## Accessing external services
Per description above, the `OrchestratorFormApi` is solemnly frontend code, meaning it is executed in the browser.

Using common backstage APIs, the widgets can retrieve data from the Backstage services or call the Backstage API.
An example of receiving two of the Backstage APIs is in the [example plugin](./custom-form-example-plugin/plugins/custom-form-example-plugin/src/plugin.ts).

Access to 3rd party external services (like the OpenShift API) might be affected by either network or CORS limitations.
To address these issues, a backstage backend plugin exposing new REST endpoints can be implemented to act as a proxy or pre-processor for big data sets.
This is out of scope for this demo, we refer to the Backstage documentation for additional details.

### Limitations
- Frontend - cors or the need of backend plugin to proxy requests to 3rd party resources
- Requires TypeScript/React coding skills
- single plugin for all workflows

## More info
- [Orchestrator Extensible Form](https://github.com/redhat-developer/rhdh-plugins/blob/main/workspaces/orchestrator/docs/extensibleForm.md)
- [Backstage plugin development](https://backstage.io/docs/plugins/structure-of-a-plugin)
- [RHDH dynamic plugins development](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/#Extend)
- [JSON Schema](https://json-schema.org/understanding-json-schema/reference)