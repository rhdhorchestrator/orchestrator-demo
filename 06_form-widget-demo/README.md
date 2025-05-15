# Form widget Demo

This directory contains the necessary resources to run the Form Widget Demo. This will demonstrate a new forntend plugin that will be provided to enhance the Orchestrator experience.

Please note the two subdirectories:

1. dynamic-course-setup: 
This directory contains a [Helm Chart](https://helm.sh/) to install the demo resources.

1. workflow
This directory contains the source code for a serverless workflow project. This workflow can be build and deployed to showcase the new plugin demonstrated. *There is no need to build this project manually, as the aforementioned Helm Chart will suffice.* For instructions to do so, please see the [workflow README](workflow/README.md)

## Overview on Workflow Components

### Dynamic Course Select Workflow
This is a simple workflow demonstrating the use of the orchestrator-form-widgets library with dynamic form behavior.

*Input Schema* Uses dynamic-course-select__main-schema.json, as explained below. 

*Execution Flow:*
The workflow starts at the Start state.
It immediately invokes the PrintSuccessData function, which returns a success message and outputs the collected data. 

*Endpoints*: Requires supporting HTTP endpoints (e.g., /courses, /coursedetailsschema) and a proxy setup to simulate dynamic form behavior.

### Dynamic Course Select Schema
This JSON Schema defines a dynamic form for selecting courses based on a student's name. It includes autocomplete, conditional data fetching, and schema updates.

* studentName: Basic text input.
* courseName: Autocomplete input that fetches course options based on studentName.
* courseDetails: Hidden field populated dynamically.
* mySchemaUpdater: Triggers schema updates when courseName changes.

Used to demonstrate dynamic form behavior with schema-driven UI components, including fetch triggers, POST requests, and conditional rendering.


## Installing the Dynamic Course Demo via Helm Chart

This Helm Chart will set up some necessary resources to use the dynamic-course-workflow in Orchestrator.

### Prerequisites

* RHDH >=1.6 and Orchestrator >=1.6
> [!NOTE]
> Currently, to install Orchestrator with RHDH 1.6 is by installing the RHDH [Helm Chart](https://github.com/rhdhorchestrator/rhdh-chart).

### Resources list
The following chart will deploy:

1. A custom serverless workflow to showcase the plugin
1. A Pod running an Express-based webserver
    Used to support the Dynamic Course Select workflow. It provides mock endpoints for dynamic field population, schema injection, and validation.
1. A service to route from the workflow run to the webserver


### Additional setup

You must add proxy configurations to the RHDH appConfig settings:

```yaml
proxy:
  reviveConsumedRequestBodies: true
  endpoints:
    '/mytesthttpserver':
      target: 'http://mytesthttpservice:80'
      allowedMethods: ['GET', 'POST']
      allowedHeaders: ['test-header']
```

Run the following command to install the chart:
`helm install <release-name> dynamic-course-setup`

After installing the Helm Chart, a new workflow should be avaliable in the Orchestrator plugin.
