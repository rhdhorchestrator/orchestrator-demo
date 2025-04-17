# 🛠️ Build image for workflow image build

This container image provides a CLI-based environment with tools required for:
* Building workflow image
* Generating workflow manifets for k8s
* Pushing image to image registry
* Deploying manifests on k8s/OCP cluster 

## 📦 Included Tools

| Tool            | Purpose                                          |
|-----------------|--------------------------------------------------|
| `podman`        | Container runtime for building the image         |
| `kubectl`       | Kubernetes CLI                                   |
| `yq`            | YAML processor                                   |
| `jq`            | JSON processor                                   |
| `curl`, `git`, `find`, `which`, `bash`, `bind-utils` | Shell utilities |
| `kn-workflow`   | CLI for generating Serverless Workflow manifests |

The image includes also a [Dockerfile](../docker/osl.Dockerfile) that is used to build the workflow's image.

---

## 🚀 How to Build with Podman

To build the container image using [Podman](https://podman.io/), run the following command in the root of the project:

### 1. Set your tag
`TAG` should be bumped accordig to the version of the kn-workflow CLI that is included in the Dockerfile.
It should be compatible with the version of the builder image as specified in [Dockerfile](../docker/osl.Dockerfile).

```bash
IMAGE=quay.io/orchestrator/orchestrator-workflow-builder
TAG=1.35
```

### 2. Build each architecture-specific image and tag it
```bash
IMAGE=quay.io/orchestrator/orchestrator-workflow-builder
TAG=1.35
podman build --platform linux/amd64 -t ${IMAGE}-amd64:${TAG} -f scripts/Dockerfile .
podman build --platform linux/arm64 -t ${IMAGE}-arm64:${TAG} -f scripts/Dockerfile .
```

### 3. Push architecture-specific images to Quay
```bash
podman push ${IMAGE}-amd64:${TAG}
podman push ${IMAGE}-arm64:${TAG}
```

### 4. Create and push the manifest list
```bash
podman manifest create ${IMAGE}:${TAG}
podman manifest add ${IMAGE}:${TAG} ${IMAGE}-amd64:${TAG}
podman manifest add ${IMAGE}:${TAG} ${IMAGE}-arm64:${TAG}

# Push the multi-arch manifest to Quay
podman manifest push ${IMAGE}:${TAG} docker://${IMAGE}:${TAG}
```
