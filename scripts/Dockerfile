FROM registry.access.redhat.com/ubi9/ubi

# Install required tools and dependencies
RUN dnf install -y --allowerasing \
        podman \
        curl \
        unzip \
        git \
        findutils \
        jq \
        which \
        bash \
        bind-utils \
        && dnf clean all

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm -f kubectl

# Install yq
RUN curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install kn-workflow plugin (v1.35.0)
RUN curl -L https://developers.redhat.com/content-gateway/file/pub/cgw/serverless-logic/1.35.0/kn-workflow-linux-amd64 \
    -o /usr/local/bin/kn-workflow \
    && chmod +x /usr/local/bin/kn-workflow

# Set workdir and copy build script and its dependencies
WORKDIR /app
COPY scripts/ scripts
COPY docker/ docker

# Make script executable
RUN chmod +x scripts/build.sh && chmod +x scripts/lib/*.sh

ENTRYPOINT ["./scripts/build.sh"]
