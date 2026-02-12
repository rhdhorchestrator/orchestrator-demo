# Token Propagation workflow
This workflow demonstrates how to configure automatic token propagation from incoming requests to downstream HTTP service calls using OIDC security schemes and Quarkus configuration.

The workflow makes three HTTP calls to a sample server, each using a different security scheme:
- **BearerToken** (OAuth2 client credentials) - propagated via `X-Authorization-First` header
- **BearerTokenOther** (OAuth2 client credentials) - propagated via `X-Authorization-Other` header
- **SimpleBearerToken** (HTTP bearer) - propagated via `X-Authorization-Simple` header

## Workflow application configuration
Application properties can be initialized from environment variables before running the application:

| Property | Description | Default |
|----------|-------------|---------|
| `auth-server-url` | Keycloak realm URL | `http://example-kc-service.keycloak:8080/realms/quarkus` |
| `client-id` | OIDC client ID | `quarkus-app` |
| `client-secret` | OIDC client secret | `lVGSvdaoDUem7lqeAnqXn1F92dCPbQea` |

## Pre-requisites
- A Keycloak instance with a realm and client configured for OIDC
- The sample server deployed (see [Installation](#installation))

### Keycloak setup

If you do not already have a Keycloak instance, install one using Operator Hub:
1. Follow [Red Hat Build of Keycloak Operator Guide](https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/22.0/html/operator_guide/installation-)
2. Create a PostgreSQL database for Keycloak
3. Create the Keycloak CR with HTTP enabled (for dev/test only)
4. Log into the Keycloak admin console and create a realm (`quarkus`) with a client (`quarkus-app`)

> [!NOTE]
> Currently this workflow is only usable when deployed on a cluster with
> * RHDH
> * Orchestrator plugin
> * Serverless Logic (Sonataflow) operator
> * A Keycloak instance for OIDC

## Input
No `inputData` fields are required. However, the execution request must include `authTokens` to supply the bearer tokens for propagation (see [Usage](#usage)).

## Installation

### Deploy the sample server
```bash
TARGET_NS=sonataflow-infra
oc apply -n ${TARGET_NS} -f sample-server/00-deploy.yaml
```

### Deploy the workflow
To install the workflow, apply the Kubernetes manifests located in the [`manifests`](./manifests/) directory.
These manifests are ordered numerically to reflect their intended deployment sequence.

> **Note**: Before deploying, ensure the following prerequisites are satisfied:
> - The PostgreSQL secret references are correctly configured in the SonataFlow Custom Resource.
> - Keycloak is accessible at the URL configured in `application.properties`.

```bash
oc apply -n sonataflow-infra -f ./09_token_propagation/manifests
```

### Verify the Deployment
To confirm the workflow was deployed successfully, run:
```bash
oc get sonataflow -n sonataflow-infra token-propagation
```

Expected output:
```
NAME                  PROFILE   VERSION   URL   READY   REASON
token-propagation     gitops    1.0             True
```

## Building the workflow
To build the workflow image and push it to the image registry, use the [../scripts/build.sh](../scripts/build.sh) script.

This workflow requires additional Quarkus extensions for OIDC support:
```bash
QUARKUS_EXTENSIONS="io.quarkus:quarkus-oidc-client,io.quarkus:quarkus-oidc" \
  ../scripts/build.sh --image=quay.io/orchestrator/demo-token-propagation:latest
```

Push the image:
```bash
POCKER=$(command -v podman || command -v docker)
$POCKER push quay.io/orchestrator/demo-token-propagation:latest
```

Build, generate manifests, and deploy in one step:
```bash
QUARKUS_EXTENSIONS="io.quarkus:quarkus-oidc-client,io.quarkus:quarkus-oidc" \
  ../scripts/build.sh --image=quay.io/orchestrator/demo-token-propagation:latest --deploy
```

## Usage
To execute the workflow, send a request with `authTokens`:
```bash
export RHDH_ROUTE=$(oc get route -n rhdh-operator backstage-developer-hub -o jsonpath='{.spec.host}')
export RHDH_BEARER_TOKEN=$(oc get secrets -n rhdh-operator backstage-backend-auth-secret -o go-template='{{ .data.BACKEND_SECRET  }}' | base64 -d)

curl -v -XPOST \
  -H "Content-type: application/json" \
  -H "Authorization: ${RHDH_BEARER_TOKEN}" \
  https://${RHDH_ROUTE}/api/orchestrator/v2/workflows/token-propagation/execute \
  -d '{"inputData":{}, "authTokens": [{"provider": "First", "token": "FIRST"}, {"provider": "Other", "token": "OTHER"}, {"provider": "Simple", "token": "SIMPLE"}]}'
```

> [!WARNING]
> With the default `quarkus.oidc` properties, the `X-Authorization-Other` header must contain a valid OIDC token. If it does not, the workflow will return a 401 error. Generate a real token from Keycloak:
> ```bash
> export access_token=$(curl -X POST "http://localhost:8080/realms/${REALM}/protocol/openid-connect/token" --user "${CLIENT_ID}:${CLIENT_SECRET}" -H 'content-type: application/x-www-form-urlencoded' -d "username=${USERNAME}&password=${PASSWORD}&grant_type=password" | jq --raw-output '.access_token')
> ```

Then check the logs for the `sample-server` pod to verify headers were propagated:
```bash
oc logs -n sonataflow-infra -l app=sample-server
```

Expected output shows each endpoint receiving the appropriate authorization header:
```
================ Headers for first ================
Authorization: Bearer FIRST
...
================ Headers for other ================
Authorization: Bearer <valid token>
...
================ Headers for simple ================
Authorization: Bearer SIMPLE
...
```
