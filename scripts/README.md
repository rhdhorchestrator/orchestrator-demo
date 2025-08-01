# 🚀 Workflow Build Script

The `build.sh` script is a comprehensive tool for building, packaging, and deploying SonataFlow workflow applications. It automates the entire process from manifest generation to deployment.

## ✨ Features

- **🏗️ Manifest Generation**: Automatically generates Kubernetes manifests using `kn-workflow`
- **📦 Container Building**: Builds workflow container images with Docker or Podman
- **🚢 Image Publishing**: Pushes images to container registries with multiple tags
- **🎯 Deployment**: Deploys manifests to Kubernetes/OpenShift clusters
- **🔧 Flexible Layouts**: Supports both Quarkus and non-Quarkus project structures
- **💾 Persistence Control**: Configurable PostgreSQL persistence (can be disabled)
- **🐳 Custom Dockerfiles**: Option to use custom Dockerfiles or embedded defaults
- **🔍 Auto-Detection**: Automatically detects and uses available container engines
- **📋 Validation**: Comprehensive input validation and dependency checking

## 📋 Prerequisites

Before using the build script, ensure you have the following requirements:

### 🖥️ System Requirements

- **Operating System**: Linux, macOS, or Windows with WSL2
- **Architecture**: amd64 (x86_64) or arm64
- **Memory**: Minimum 4GB RAM (8GB+ recommended for large workflows)
- **Disk Space**: At least 2GB free space for container builds

### 🔧 Required Tools

| Tool | Minimum Version | Purpose | Installation |
|------|----------------|---------|--------------|
| **`kn-workflow`** | 1.36.0+ | Manifest generation | [OSL docs](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.36/html/installing_openshift_serverless/serverless-logic-install-kn-workflow-plugin-cli) |
| **`yq`** | 4.0+ | YAML processing | [yq releases](https://github.com/mikefarah/yq/releases) |
| **`git`** | 2.0+ | Version control & tagging | System package manager |
| **Container Engine** | - | Image building | Docker or Podman (see below) |

#### Container Engine (Choose One)

**Option 1: Docker**
```bash
# Linux (Ubuntu/Debian)
sudo apt-get update && sudo apt-get install docker.io
sudo usermod -aG docker $USER

# macOS
brew install docker

# Verify installation
docker --version
docker run hello-world
```

**Option 2: Podman**
```bash
# Linux (RHEL/Fedora)
sudo dnf install podman

# Linux (Ubuntu/Debian) 
sudo apt-get install podman

# macOS
brew install podman

# Verify installation
podman --version
podman run hello-world
```

### 🚀 Optional Tools (for deployment)

| Tool | Purpose | Installation |
|------|---------|--------------|
| **`kubectl`** | Kubernetes deployment | [Kubernetes CLI](https://kubernetes.io/docs/tasks/tools/) |
| **`oc`** | OpenShift deployment | [OpenShift CLI](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html) |

### 🔐 Access Requirements

#### Container Registry Access
- **Pull Access**: Access to Red Hat registries for base images
- **Push Access**: Write permissions to your target container registry
- **Authentication**: Registry credentials configured

```bash
# Example: Login to Quay.io
docker login quay.io
# or
podman login quay.io
```

#### Kubernetes/OpenShift Access (for deployment)
- **Cluster Access**: Valid kubeconfig or oc login session
- **Permissions**: Namespace creation/management permissions
- **Network Access**: Connectivity to cluster API endpoint

```bash
# Verify cluster access
kubectl cluster-info
# or
oc status
```

### 🌐 Network Requirements

- **Internet Access**: Required for downloading dependencies and base images
- **Registry Access**: Connectivity to `registry.redhat.io` and `registry.access.redhat.com`
- **Cluster Access**: Network connectivity to your Kubernetes/OpenShift cluster (for deployment)

### 📦 Project Structure Requirements

Your workflow project must have one of these layouts:

**Quarkus Layout** (default):
- `src/main/resources/*.sw.yaml` - Workflow definition
- `src/main/resources/schemas/` - JSON schemas (optional)
- `src/main/resources/specs/` - OpenAPI specs (optional)

**Non-Quarkus Layout** (`--non-quarkus` flag):
- `*.sw.yaml` - Workflow definition in project root
- `schemas/` - JSON schemas (optional)
- `specs/` - OpenAPI specs (optional)

### ✅ Quick Verification

Run this command to check your setup:

```bash
# Check all required tools
echo "=== Checking Prerequisites ==="
kn-workflow version && echo "✅ kn-workflow: OK" || echo "❌ kn-workflow: MISSING"
yq --version && echo "✅ yq: OK" || echo "❌ yq: MISSING"
git --version && echo "✅ git: OK" || echo "❌ git: MISSING"

# Check container engine
if command -v docker >/dev/null 2>&1; then
    docker --version && echo "✅ docker: OK"
elif command -v podman >/dev/null 2>&1; then
    podman --version && echo "✅ podman: OK"
else
    echo "❌ Container engine: MISSING (need docker or podman)"
fi

# Check optional tools
kubectl version --client 2>/dev/null && echo "✅ kubectl: OK" || echo "⚠️ kubectl: MISSING (needed for deployment)"
```

## 🚀 Quick Start

### Basic Usage

```bash
# Build and generate manifests only
./scripts/build.sh --image=quay.io/myorg/myworkflow:latest

# Build, push, and deploy
./scripts/build.sh --image=quay.io/myorg/myworkflow:latest --deploy

# Disable persistence for lightweight builds
./scripts/build.sh --image=quay.io/myorg/myworkflow:latest --no-persistence
```

### Advanced Usage

```bash
# Custom namespace and manifests directory
./scripts/build.sh \
  --image=quay.io/myorg/myworkflow:v1.0.0 \
  --namespace=my-workflows \
  --manifests-directory=./custom-manifests \
  --deploy

# Non-Quarkus project layout
./scripts/build.sh \
  --image=quay.io/myorg/myworkflow:latest \
  --non-quarkus \
  --workflow-directory=./my-workflow

# Custom Dockerfile and container engine
./scripts/build.sh \
  --image=quay.io/myorg/myworkflow:latest \
  --dockerfile=./custom.Dockerfile \
  --container-engine=podman
```

## 📋 Command Line Options

| Flag | Description | Default |
|------|-------------|---------|
| `-i\|--image=<string>` | **[Required]** Full container image path | - |
| `-b\|--builder-image=<string>` | Override builder image | `registry.redhat.io/openshift-serverless-1/logic-swf-builder-rhel8:1.36.0-8` |
| `-r\|--runtime-image=<string>` | Override runtime image | `registry.access.redhat.com/ubi9/openjdk-17:1.21-2` |
| `-d\|--dockerfile=<string>` | Path to custom Dockerfile | Uses embedded default |
| `-n\|--namespace=<string>` | Target Kubernetes namespace | Current namespace |
| `-m\|--manifests-directory=<string>` | Manifests output directory | `./manifests` |
| `-w\|--workflow-directory=<string>` | Workflow project directory | Current directory |
| `-c\|--container-engine=<string>` | Container engine (docker/podman) | Auto-detect |
| `-P\|--no-persistence` | Disable PostgreSQL persistence | Persistence enabled |
| `-S\|--non-quarkus` | Use non-Quarkus project layout | Quarkus layout |
| `--push` | Push image to registry | No push |
| `--deploy` | Deploy manifests to cluster | No deployment |
| `-h\|--help` | Show help message | - |

## 🏗️ Build Process

The script performs these steps in order:

1. **🔍 Validation**: Checks dependencies and validates inputs
2. **📄 Manifest Generation**: Uses `kn-workflow gen-manifest` to create Kubernetes resources
3. **⚙️ Persistence Configuration**: Adds PostgreSQL persistence (if enabled)
4. **🏗️ Image Building**: Builds the container image with appropriate extensions
5. **🏷️ Tagging**: Tags image with commit hash and 'latest'
6. **🚢 Publishing**: Pushes image to registry (if `--push` specified)
7. **🎯 Deployment**: Applies manifests to cluster (if `--deploy` specified)

## 🔧 Environment Variables

The script respects these environment variables:

| Variable | Purpose | Example |
|----------|---------|---------|
| `QUARKUS_EXTENSIONS` | Additional Quarkus extensions | `io.quarkus:quarkus-redis-client` |
| `MAVEN_ARGS_APPEND` | Additional Maven build arguments | `-DskipTests=true` |
| `DEBUGME` | Enable debug output | `DEBUGME=1` |

## 📁 Project Layouts

### Quarkus Layout (Default)
```
my-workflow/
├── src/main/resources/
│   ├── workflow.sw.yaml
│   ├── schemas/
│   └── specs/
├── src/main/java/
└── pom.xml
```

### Non-Quarkus Layout (`--non-quarkus`)
```
my-workflow/
├── workflow.sw.yaml
├── schemas/
└── specs/
```

## 💾 Persistence Configuration

By default, the script configures PostgreSQL persistence for workflow state. This can be disabled with `--no-persistence`:

**With Persistence (default):**
- Includes JDBC and PostgreSQL Quarkus extensions
- Configures database connection parameters
- Adds persistence configuration to SonataFlow CR

**Without Persistence (`--no-persistence`):**
- Excludes persistence-related extensions
- Reduces image size and complexity
- Suitable for stateless or ephemeral workflows



## 🐳 Container Images

### Default Images

The script uses Red Hat's OpenShift Serverless Logic images by default:

- **Builder**: `registry.redhat.io/openshift-serverless-1/logic-swf-builder-rhel8:1.36.0-8`
- **Runtime**: `registry.access.redhat.com/ubi9/openjdk-17:1.21-2`

### Custom Dockerfiles

You can provide a custom Dockerfile with the `-d|--dockerfile` flag:

```bash
./scripts/build.sh --image=myimage:tag --dockerfile=./my-custom.Dockerfile
```

The embedded default Dockerfile supports both Quarkus and non-Quarkus layouts automatically.

## 🛠️ Troubleshooting

### Common Issues

**Missing dependencies:**
```bash
# Check if tools are available
kn-workflow version
yq --version
docker --version  # or podman --version
```

**Permission errors:**
```bash
# Ensure container engine is accessible
sudo usermod -aG docker $USER  # For Docker
# or configure Podman rootless
```

**Build failures:**
```bash
# Enable debug mode for detailed output
DEBUGME=1 ./scripts/build.sh --image=myimage:tag
```

---

# 🛠️ Orchestrator Workflow Builder Image

This section covers building the container image that provides the CLI environment for the build script.

## 📦 Included Tools

| Tool | Purpose |
|------|---------|
| `podman` | Container runtime for building images |
| `kubectl` | Kubernetes CLI |
| `yq` | YAML processor |
| `jq` | JSON processor |
| `curl`, `git`, `find`, `which`, `bash`, `bind-utils` | Shell utilities |
| `kn-workflow` | CLI for generating SonataFlow manifests |

## 🚀 Building the Orchestrator Image

### 1. Set Image Tag
```bash
IMAGE=quay.io/orchestrator/orchestrator-workflow-builder
TAG=1.36  # Match kn-workflow version
```

### 2. Build Multi-Arch Images
```bash
podman build --platform linux/amd64 -t ${IMAGE}-amd64:${TAG} -f scripts/Dockerfile.orchestrator-workflow-builder .
podman build --platform linux/arm64 -t ${IMAGE}-arm64:${TAG} -f scripts/Dockerfile.orchestrator-workflow-builder .
```

### 3. Push Architecture-Specific Images
```bash
podman push ${IMAGE}-amd64:${TAG}
podman push ${IMAGE}-arm64:${TAG}
```

### 4. Create Multi-Arch Manifest
```bash
podman manifest create ${IMAGE}:${TAG}
podman manifest add ${IMAGE}:${TAG} ${IMAGE}-amd64:${TAG}
podman manifest add ${IMAGE}:${TAG} ${IMAGE}-arm64:${TAG}
podman manifest push ${IMAGE}:${TAG} docker://${IMAGE}:${TAG}
```

## 📋 Version Alignment

Ensure the correct `kn-workflow` version for your Orchestrator release:

| Orchestrator Version | Required `kn-workflow` Version |
|----------------------|-------------------------------|
| 1.4, 1.5             | 1.35                          |
| 1.6                  | 1.36                          |

### When to Rebuild

Rebuild the orchestrator image when:
- The `build.sh` script changes significantly
- Upgrading `kn-workflow` CLI version
- Adding new tools or dependencies
- Updating base images for security patches

Always validate the image after rebuilding to ensure compatibility with the build script.
