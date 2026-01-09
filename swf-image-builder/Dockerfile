FROM registry.redhat.io/openshift-serverless-1/logic-swf-builder-rhel9:1.37.0-19

ENV QUARKUS_PLATFORM_GROUPID=com.redhat.quarkus.platform
ENV QUARKUS_PLATFORM_VERSION=3.15.4.redhat-00001

# Additional Java/Maven arguments to pass to the builder
ARG MAVEN_ARGS_APPEND
ENV MAVEN_ARGS_APPEND=${MAVEN_ARGS_APPEND}

COPY --chown=1001 ./pom.xml /home/kogito/serverless-workflow-project/pom.xml

WORKDIR /home/kogito/serverless-workflow-project

# First: prepare dependencies for offline use
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

