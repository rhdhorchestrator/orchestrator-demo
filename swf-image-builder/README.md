### 📦 `Dockerfile`

[Dockerfile](./Dockerfile) is used to build a custom builder image that includes 

---

### 🔧 Build Command

On Linux amd64 machine run:
```bash
podman build -t quay.io/kubesmarts/logic-swf-builder-rhel8:1.36.0-kafka-persistence .
```

On Linux aarch64/macos run:
```bash
docker buildx build --platform linux/amd64 -t quay.io/kubesmarts/logic-swf-builder-rhel8:1.36.0-kafka-persistence --load .
```

---

### 🔍 Behavior Summary

* Maven dependencies and Quarkus extensions are downloaded in the first command.
* The second command ensures the image is clean but **keeps the local `.m2` repository cache intact**, enabling **offline builds**.

Let me know if you’d like a multi-stage version to optimize image size further or a variant that resolves the environment variables statically.
