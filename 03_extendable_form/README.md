# Custom UI widgets extending the execution form 

TBD: What, where
JSONSchema input params

The workflow execution form collecting input parameters capabilities can be extended for custom-developed React/TypeScript components (widgets) to either customize look&feel, perform data retrieval, do validations, handle simple business logic or provide context-awareness among form components.

The set of input parameters for a workflow execution is defined by [JSON Schema](https://json-schema.org/understanding-json-schema/reference) referenced from the workflow definition via `dataInputSchema` property. The UI leverages the [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form) to compose the UI form conforming the requested input JSON schema. Using following capability, the common data types can be extended for any TypeScript/React components.

## Sample workflow
For the purpose of the

## Custom widget development

TBD: Frontend-only

Custom React/TypeScript widgets referenceable from the workflow's data input schema are supplied via a custom-developed Backstage frontend plugin.

Such frontend plugin is of the common [Backstage architecture](https://backstage.io/docs/plugins/structure-of-a-plugin) and its purpose is to export API providing the custom widgets in the form of a [react-jsonschema-form](https://github.com/rjsf-team/react-jsonschema-form)-component decorator.

The API implementation needs to be of `orchestratorFormApiRef` ID and it needs to implement the `OrchestratorFormApi` TypeScript interface (from the `@red-hat-developer-hub/backstage-plugin-orchestrator-form-api` NPM dependency).

An example is provided in the [custom-form-example-plugin](./custom-form-example-plugin/plugins/custom-form-example-plugin).

The API implementation 

### Limitations
- Frontend - cors or the need of backend plugin to proxy requests to 3rd party resources
- Requires TypeScript/React coding skills

## More info
- [Orchestrator Extensible Form](https://github.com/redhat-developer/rhdh-plugins/blob/main/workspaces/orchestrator/docs/extensibleForm.md)
- [Backstage plugin development](https://backstage.io/docs/plugins/structure-of-a-plugin)
- [RHDH dynamic plugins development](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/#Extend)
- [JSON Schema](https://json-schema.org/understanding-json-schema/reference)