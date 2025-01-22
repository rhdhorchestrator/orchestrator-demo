# 03_extendable_form

This project uses Quarkus, the Supersonic Subatomic Java Framework.

If you want to learn more about Quarkus, please visit its website: https://quarkus.io/ .

## Running the application in dev mode

You can run your application in dev mode that enables live coding using:
```shell script
./mvnw compile quarkus:dev
```

> **_NOTE:_**  Quarkus now ships with a Dev UI, which is available in dev mode only at http://localhost:8080/q/dev/.

## Packaging and running the application

The application can be packaged using:
```shell script
./mvnw package
```
It produces the `quarkus-run.jar` file in the `target/quarkus-app/` directory.
Be aware that it’s not an _über-jar_ as the dependencies are copied into the `target/quarkus-app/lib/` directory.

The application is now runnable using `java -jar target/quarkus-app/quarkus-run.jar`.

If you want to build an _über-jar_, execute the following command:
```shell script
./mvnw package -Dquarkus.package.type=uber-jar
```

The application, packaged as an _über-jar_, is now runnable using `java -jar target/*-runner.jar`.

## Creating a native executable

You can create a native executable using: 
```shell script
./mvnw package -Dnative
```

Or, if you don't have GraalVM installed, you can run the native executable build in a container using: 
```shell script
./mvnw package -Dnative -Dquarkus.native.container-build=true
```

You can then execute your native executable with: `./target/03_extented-1.0.0-SNAPSHOT-runner`

If you want to learn more about building native executables, please consult https://quarkus.io/guides/maven-tooling.

## Building the workflow
From the root folder of the the repository, use the `./scripts/build-push.sh`, but make sure it points
to the correct image registry and organization (currently it points to `quay.io/orchestrator`).
The script will build workflow's image and push it to the image registry:
```
WORKFLOW_ID=extendable-workflow WORKFLOW_FOLDER=03_extendable_form ./scripts/build-push.sh
```

# Deploying the workflow
From the root folder of the the repository, run (with correctly placed parameters) the following to generate the manifests required to deploy the workflow on OCP cluster:
```
WORKFLOW_ID=extendable-workflow WORKFLOW_FOLDER=03_extendable_form WORKFLOW_IMAGE_REGISTRY=quay.io WORKFLOW_IMAGE_NAMESPACE=orchestrator ./scripts/gen-manifest.sh
```
The output will include a directory that contains the relevant manifests to be deployed on the cluster.
```
...
Manifests generated in /tmp/tmp.TzmxX4AIWW/03_extendable_form/src/main/resources/manifests
```
The list of files are in a specific order to be deployed on a cluster:
```
ls -1 /tmp/tmp.TzmxX4AIWW/03_extendable_form/src/main/resources/manifests
01-configmap_extendable-workflow-props.yaml
02-configmap_01-extendable-workflow-resources-schemas.yaml
03-sonataflow_extendable-workflow.yaml
```

To deploy the workflow run switch to the manifests directory and run:
```
oc apply -f 01-configmap_extendable-workflow-props.yaml -n sonataflow-infra
oc apply -f 03-sonataflow_extendable-workflow.yaml -n sonataflow-infra
```
(the 02-configmap_01-extendable-workflow-resources-schemas.yaml isn't mandatory).

and verify both workflow's CR and workflow's pod are ready:
```
oc get sonataflow -n sonataflow-infra extendable-workflow 
NAME                  PROFILE   VERSION   URL   READY   REASON
extendable-workflow   gitops    1.0             True

oc get pods -n sonataflow-infra -l sonataflow.org/workflow-app=extendable-workflow
NAME                                   READY   STATUS    RESTARTS   AGE
extendable-workflow-68ff48fdb6-7wcrc   1/1     Running   0          10m
```

It is recommended to deploy the manifests to the `sonataflow-infra` namespace, unless other namespace is [properly configured](https://github.com/rhdhorchestrator/orchestrator-helm-operator/tree/main/docs/release-1.3#additional-workflow-namespaces).


## Related Guides

- Kubernetes ([guide](https://quarkus.io/guides/kubernetes)): Generate Kubernetes resources from annotations
- SmallRye Health ([guide](https://quarkus.io/guides/smallrye-health)): Monitor service health

## Provided Code

### RESTEasy JAX-RS

Easily start your RESTful Web Services

[Related guide section...](https://quarkus.io/guides/getting-started#the-jax-rs-resources)

### SmallRye Health

Monitor your application's health using SmallRye Health

[Related guide section...](https://quarkus.io/guides/smallrye-health)
