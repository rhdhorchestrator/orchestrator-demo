### AAP DB Deploy Workflow

Coordinates software template creation, namespace management, AAP job execution, GitHub Actions monitoring, and ArgoCD deployment.

- The main flow `aap-db-deploy-main` orchestrates the end-to-end process.
- Subflows: `softwareTemplate`, `namespaceManagement`, `aapJob`, `githubActions`.
- Each subflow can be run individually like the main flow.


### Flows and schemas

| Flow ID | Flow filename | dataInputSchema file |
|---|---|---|
| aap-db-deploy-main | `src/main/resources/aap-db-deploy-main.sw.yaml` | `src/main/resources/schemas/aap-db-deploy-flow-main-input-schema.json` |
| softwareTemplate | `src/main/resources/subflows/software-template.sw.yaml` | `src/main/resources/schemas/aap-db-deploy-flow-sotware-template-input-schema.json` |
| namespaceManagement | `src/main/resources/subflows/namespace-management.sw.yaml` | `src/main/resources/schemas/aap-db-deploy-flow-namespace-management-input-schema.json` |
| aapJob | `src/main/resources/subflows/aap-job.sw.yaml` | `src/main/resources/schemas/aap-db-deploy-flow-aap-input-schema.json` |
| githubActions | `src/main/resources/subflows/github-actions.sw.yaml` | `src/main/resources/schemas/aap-db-deploy-flow-github-actions-input-schema.json` |

### Main flow description

- **aap-db-deploy-main**: Orchestrates the end-to-end deployment. It launches the `softwareTemplate` subflow, checks its continuation flag, then `namespaceManagement`, `aapJob`, and `githubActions` in sequence, each time continuing only on success. 
Finally, it creates the ArgoCD Application pointing to the generated GitOps repo and sends a success notification with helpful links.

### Subflow descriptions

- **softwareTemplate**: Launches a software template via Scaffolder API, polls the task until completion or failure, sets a continue/stop flag for the orchestrmain workflow, and sends notifications with a link to the created component.
- **namespaceManagement**: Checks whether the target OpenShift namespace exists; if not, creates it. Patches the namespace with an ArgoCD management label. Sends notifications for either path. Always signals continue.
- **aapJob**: Launches an AAP job using the configured job template and parameters, polls job status to completion/failure, and sends notifications including a link to the AAP job output page. Signals continue on success.
- **githubActions**: Finds the repository “CI” workflow, polls the latest run until it succeeds/fails, and sends notifications including a link to the GitHub Actions run. Signals continue on success.

### Flow-specific curl examples

#### Main flow: aap-db-deploy-main
```bash
curl --location 'http://localhost:8080/aap-db-deploy-main' \
--header 'Content-Type: application/json' \
--data '{
  "component": {
    "orgName": "your-org",
    "repoName": "spring-petclinic",
    "description": "Spring PetClinic Application",
    "owner": "group:default/development",
    "system": "system:default/janus-orchestrator",
    "port": 8080
  },
  "java": {
    "groupId": "org.springframework.samples",
    "artifactId": "spring-petclinic",
    "javaPackageName": "org/springframework/samples/petclinic"
  },
  "ci": {
    "ciMethod": "./skeletons/github-actions/",
    "imageRepository": "quay.io",
    "imageNamespace": "your-namespace"
  },
  "aap": {
    "jobTemplate": "postgres_rhel",
    "inventoryGroup": "2",
    "limit": "1"
  },
  "notifications": {
    "recipients": ["group:default/development"]
  }
}'
```

#### Subflow: softwareTemplate
```bash
curl --location 'http://localhost:8080/softwareTemplate' \
--header 'Content-Type: application/json' \
--data '{
  "component": {
    "orgName": "your-org",
    "repoName": "spring-petclinic",
    "description": "Spring PetClinic Application",
    "owner": "group:default/development",
    "system": "system:default/janus-orchestrator",
    "port": 8080
  },
  "java": {
    "groupId": "org.springframework.samples",
    "artifactId": "spring-petclinic",
    "javaPackageName": "org/springframework/samples/petclinic"
  },
  "ci": {
    "ciMethod": "./skeletons/github-actions/",
    "imageRepository": "quay.io",
    "imageNamespace": "your-namespace"
  },
  "aap": {
    "jobTemplate": "postgres_rhel",
    "inventoryGroup": "2",
    "limit": "1"
  },
  "notifications": {
    "recipients": ["group:default/development"]
  }
}'
```

#### Subflow: namespaceManagement
```bash
curl --location 'http://localhost:8080/namespaceManagement' \
--header 'Content-Type: application/json' \
--data '{
  "notifications": {
    "recipients": ["group:default/development"]
  }
}'
```

#### Subflow: aapJob
```bash
curl --location 'http://localhost:8080/aapJob' \
--header 'Content-Type: application/json' \
--data '{
  "aap": {
    "jobTemplate": "postgres_rhel",
    "inventoryGroup": "2",
    "limit": "1"
  },
  "notifications": {
    "recipients": ["group:default/development"]
  }
}'
```

#### Subflow: githubActions
```bash
curl --location 'http://localhost:8080/githubActions' \
--header 'Content-Type: application/json' \
--data '{
  "component": {
    "orgName": "your-org",
    "repoName": "spring-petclinic",
    "description": "Spring PetClinic Application",
    "owner": "group:default/development",
    "system": "system:default/janus-orchestrator",
    "port": 8080
  },
  "java": {
    "artifactId": "spring-petclinic"
  },
  "notifications": {
    "recipients": ["group:default/development"]
  }
}'
```