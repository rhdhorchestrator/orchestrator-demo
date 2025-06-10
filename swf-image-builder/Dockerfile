FROM registry.redhat.io/openshift-serverless-1/logic-swf-builder-rhel8:1.36.0-8

ENV QUARKUS_PLATFORM_GROUPID=com.redhat.quarkus.platform
ENV QUARKUS_PLATFORM_VERSION=3.15.4.redhat-00001

# Additional Java/Maven arguments to pass to the builder
ARG MAVEN_ARGS_APPEND
ENV MAVEN_ARGS_APPEND=${MAVEN_ARGS_APPEND}

# Create the .quarkus directory and set correct ownership
# RUN mkdir -p /home/kogito/.quarkus

# Copy config.yaml to the .quarkus directory
# COPY --chown=1001 ./config.yaml /home/kogito/.quarkus/config.yaml

# RUN chown -R 1001:0 /home/kogito/.quarkus

COPY --chown=1001 ./pom.xml /home/kogito/serverless-workflow-project/pom.xml
#RUN chown 1001:0 /home/kogito/serverless-workflow-project/pom.xml

WORKDIR /home/kogito/serverless-workflow-project

# First: prepare dependencies for offline use
#RUN mvn -B ${MAVEN_ARGS_APPEND} \
RUN mvn -B ${MAVEN_ARGS_APPEND} \
    -nsu \
    -DskipTests=true \
    -Dmaven.javadoc.skip=true \
    clean dependency:go-offline \
    "${QUARKUS_PLATFORM_GROUPID}":quarkus-maven-plugin:"${QUARKUS_PLATFORM_VERSION}":go-offline install

# Second: cleanup the build state while preserving cache
RUN mvn \
    -nsu \
    -B \
    clean

