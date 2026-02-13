# Token Propagation workflow
This workflow demonstrates how to configure automatic token propagation from incoming requests to downstream HTTP service calls using OIDC security schemes and Quarkus configuration.

The workflow makes three HTTP calls to a sample server, each using a different security scheme:
- **BearerToken** (OAuth2 client credentials) - propagated via `X-Authorization-Oauth2` header
- **BearerTokenOther** (OAuth2 client credentials) - propagated via `X-Authorization-Oauth2` header
- **SimpleBearerToken** (HTTP bearer) - propagated via `X-Authorization-Simplebearertoken` header

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
The orchestrator API requires a Backstage identity token, not a backend secret. Obtain one by exchanging a Keycloak password grant refresh token with the Backstage auth endpoint.

**Step 1 -- Get a Keycloak token via password grant:**
```bash
export KC_ROUTE=$(oc get route keycloak -n rhsso-operator -o jsonpath='{.spec.host}')
export KC_TOKEN_RESPONSE=$(curl -sk -X POST "https://${KC_ROUTE}/auth/realms/basic/protocol/openid-connect/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=password&client_id=rhdh&client_secret=${KC_CLIENT_SECRET}&username=${VERIFICATION_USER}&password=${VERIFICATION_PASSWORD}&scope=openid")
export REFRESH_TOKEN=$(echo "$KC_TOKEN_RESPONSE" | jq -r '.refresh_token // empty')
export OIDC_TOKEN=$(echo "$KC_TOKEN_RESPONSE" | jq -r '.access_token // empty')
```

**Step 2 -- Exchange the refresh token for a Backstage identity token:**
```bash
export RHDH_ROUTE=$(oc get route -n rhdh-operator backstage-developer-hub -o jsonpath='{.spec.host}')
export BACKSTAGE_RESPONSE=$(curl -sk "https://${RHDH_ROUTE}/api/auth/oidc/refresh?optional&scope=openid%20profile%20email&env=development" -H "x-requested-with: XMLHttpRequest" --cookie "oidc-refresh-token=${REFRESH_TOKEN}")
export BACKSTAGE_TOKEN=$(echo "$BACKSTAGE_RESPONSE" | jq -r '.backstageIdentity.token // empty')
```

**Step 3 -- Execute the workflow:**
```bash
curl -sk -X POST "https://${RHDH_ROUTE}/api/orchestrator/v2/workflows/token-propagation/execute" -H "Content-Type: application/json" -H "Authorization: Bearer ${BACKSTAGE_TOKEN}" -d '{"inputData":{}, "authTokens": [{"provider": "OAuth2", "token": "'"${OIDC_TOKEN}"'"}, {"provider": "SimpleBearerToken", "token": "test-simple-bearer-token-value"}]}'
```

> [!WARNING]
> The `OAuth2` auth token must contain a valid Keycloak OIDC token. If it does not, the workflow will return a 401 error. Ensure the Keycloak password grant in Step 1 succeeds and returns a valid `access_token` before executing the workflow.

Then check the logs for the `sample-server` pod to verify headers were propagated:
```bash
oc logs -n sonataflow-infra -l app=sample-server
```

Expected output shows each endpoint receiving the propagated authorization headers:
```
================ Headers for first ================
X-Authorization-Oauth2: <keycloak-jwt>
X-Authorization-Simplebearertoken: test-simple-bearer-token-value
...
================ Headers for other ================
X-Authorization-Oauth2: <keycloak-jwt>
X-Authorization-Simplebearertoken: test-simple-bearer-token-value
...
================ Headers for simple ================
X-Authorization-Oauth2: <keycloak-jwt>
X-Authorization-Simplebearertoken: test-simple-bearer-token-value
...
```
