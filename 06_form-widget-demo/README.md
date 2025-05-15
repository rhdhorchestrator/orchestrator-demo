# Form widget Demo

This directory contains the necessary resources to run the Form Widget Demo. This will demonstrate a new forntend plugin that will be provided to enhance the Orchestrator experience.

Please note the two subdirectories:

1. dynamic-course-setup: 
This directory contains a [Helm Chart](https://helm.sh/) to install the demo resources.

1. workflow
This directory contains the source code for a serverless workflow project. This workflow can be build and deployed to showcase the new plugin demonstrated. *There is no need to build this project manually, as the aforementioned Helm Chart will suffice.* For instructions to do so, please see the [workflow README](workflow/README.md)

## Using the Dynamic Course Helm Chart

This Helm Chart will set up some necessary resources to use the dynamic-course-workflow in Orchestrator.

### Prerequisites

* RHDH >=1.6 and Orchestrator >=1.6
> [!NOTE]
> Currently, to install Orchestrator with RHDH 1.6 is by installing the RHDH [Helm Chart](https://github.com/redhat-developer/rhdh-chart).

### Resources list
The following chart will deploy:

1. A custom serverless workflow to showcase the plugin
1. A webserver running in a Pod.
1. A service to accept incoming requests from the workflow run


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
`helm install <release> dynamic-course-setup`

After installing the Helm Chart, a new workflow should be avaliable in the Orchestrator plugin.
