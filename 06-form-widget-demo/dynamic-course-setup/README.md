# Dynamic Course workflow setup 

This Helm Chart will set up some necessary resources to use the dynamic-course-workflow in Orchestrator.

## Resources list
The following chart will deploy:
1. A pod to run a web server
1. A service to accept incoming requests from th workflow run

## Additional setup
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
`helm install <name> .` 
