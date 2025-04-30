# 🧰 Using the Workflow Builder Image

This container image provides a self-contained environment for building and deploying SonataFlow projects. It wraps a `build.sh` script that simplifies the process from manifest generation to deployment.
The script can be used directly from Linux/MacOS instead of using the container image, given all of the tools avaiable.

---

## ✅ What the Image Does

When you run the container, it invokes the `build.sh` script, which performs the following:

1. **Generates SonataFlow manifests** using the [`kn-workflow`](https://github.com/kiegroup/kogito-tooling) plugin (v1.35.0 required).
2. **Builds the workflow image** using either Podman or Docker.
3. **Optionally deploys** the workflow:
   - Pushes the built image to the container registry.
   - Applies the generated manifests to the current Kubernetes cluster using `kubectl`.

---

## 📌 Script Usage

```text
Usage:
/app/scripts/build.sh [flags]
```

### Flags:

| Flag | Description |
|------|-------------|
| `-i`, `--image=<string>` | **(Required)** Full image name to build and optionally push (e.g., `quay.io/org/app:tag`). |
| `-b`, `--builder-image=<string>` | Override the builder image used during the workflow image build. |
| `-r`, `--runtime-image=<string>` | Override the base image for running the workflow. |
| `-n`, `--namespace=<string>` | Target Kubernetes namespace. Defaults to current context namespace. |
| `-m`, `--manifests-directory=<string>` | Directory for outputting the generated manifests. Defaults to `./manifests`. |
| `-w`, `--workflow-directory=<string>` | Directory containing the workflow's `src/`. Defaults to current directory. |
| `-P`, `--no-persistence` | Disables persistence configuration in SonataFlow CR. |
| `--push` | Pushes the workflow image to the specified registry. |
| `--deploy` | Applies the generated manifests to the cluster. |
| `-h`, `--help` | Displays usage help. |

---

## 🚀 Running the Container

Here’s a typical command used to build and optionally push the workflow image:

### Running with podman:
```bash
TARGET_WORKFLOW_IMAGE= # .e.g quay.io/your-org/workflow-repo-name:<tag>
podman run --rm \
  --privileged \
  -v $HOME/.config/containers/auth.json:/root/.config/containers/auth.json:ro \
  -v $HOME/.docker/config.json:/root/.docker/config.json:ro \
  -v $(pwd)/05_software_template_hello_world/workflow:/workspace \
  quay.io/orchestrator/orchestrator-workflow-builder:1.35 \
  -i $TARGET_WORKFLOW_IMAGE \
  -w /workspace \
  -m /workspace/manifests \
  --push
```

On MacOS, it may be needed adding `--network=host` if the container fails to pull Maven dependencies.

### Running with docker:
```bash
TARGET_WORKFLOW_IMAGE= # .e.g quay.io/your-org/workflow-repo-name:<tag>
docker run --rm \
  --privileged \
  -v $HOME/.docker/config.json:/root/.docker/config.json:ro \
  -v $(pwd)/05_software_template_hello_world/workflow:/workspace \
  quay.io/orchestrator/orchestrator-workflow-builder:1.35 \
  -i $TARGET_WORKFLOW_IMAGE \
  -w /workspace \
  -m /workspace/manifests \
  --push
```

### Running with additional Quarkus extensions or Maven arguments
When there is a need to include additional Quarkus extensions, there is a need to specify them via `QUARKUS_EXTENSIONS` variable.
For adding specific Maven arguments, provide them via `MAVEN_ARGS_APPEND` variable.
```bash
TARGET_WORKFLOW_IMAGE= # .e.g quay.io/your-org/workflow-repo-name:<tag>
podman run --rm \
  --privileged \
  --network=host \
  --env QUARKUS_EXTENSIONS="io.quarkus:quarkus-smallrye-reactive-messaging-kafka" \
  -v $HOME/.config/containers/auth.json:/root/.config/containers/auth.json:ro \
  -v $HOME/.docker/config.json:/root/.docker/config.json:ro \
  -v $(pwd)/05_software_template_hello_world/workflow:/workspace \
  quay.io/orchestrator/orchestrator-workflow-builder:1.35 \
  -i $TARGET_WORKFLOW_IMAGE \
  -w /workspace \
  -m /workspace/manifests \
  --push
```


### 🔍 Explanation of Each Part:

| Section | Description |
|--------|-------------|
| `--network=host` | Required for local registry access or cluster communication. |
| `--privileged` | Grants extended privileges (needed for Podman-in-Podman). |
| `-v $HOME/.config/containers/auth.json:/root/...` | Mounts container registry credentials for image push. |
| `-v $(pwd)/...:/workspace` | Mounts the local workflow directory into the container. |
| `-i quay.io/...` | The final image name for the built workflow. |
| `-w /workspace` | Path to the workflow source directory. |
| `-m /workspace/manifests` | Output directory for generated manifests. |
| `--push` | Push the built image to the registry. |

For debug, you may want to add `--env DEBUGME=true` to the command above.

## 🚀 Deploying the Generated Manifests

If you only wish to deploy the application after generating the manifests (without re-running the builder), use the following `kubectl` command:

```bash
kubectl apply -f /path/to/generated/manifests
```

Replace `/path/to/generated/manifests` with the directory path used during the build process (e.g., `./manifests` or what was passed with the `-m` flag).

To deploy to a specific namespace, either:

- Add `-n <namespace>` to the command, or  
- Set the context namespace via:  
  ```bash
  kubectl config set-context --current --namespace=<your-namespace>
  ```
  or
  ```bash
  oc project <your-project>
  ```
  

## 📦 Notes

- You must be logged in to your image registry from the running machine and have a valid `auth.json` file.
- Your workflow directory should follow the expected structure, aka quarkus layout (`src/main/resources/`, etc.).
- To **only generate manifests and build workflow image**, omit the `--push` and `--deploy` flags.
- Use `--deploy` to apply the manifests to your current `kubectl` context.
