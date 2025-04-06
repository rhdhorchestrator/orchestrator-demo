ARG BUILDER_IMAGE
ARG RUNTIME_IMAGE

FROM ${BUILDER_IMAGE:-registry.redhat.io/openshift-serverless-1/logic-swf-builder-rhel8:1.35.0-6} AS builder

# Variables that can be overridden by the builder
# To add a Quarkus extension to your application
ARG QUARKUS_EXTENSIONS
ENV QUARKUS_EXTENSIONS=${QUARKUS_EXTENSIONS}

# Additional Java/Maven arguments to pass to the builder
ARG MAVEN_ARGS_APPEND
ENV MAVEN_ARGS_APPEND=${MAVEN_ARGS_APPEND}

COPY --chown=1001 . .

RUN /home/kogito/launch/build-app.sh

#=============================
# Runtime
#=============================
FROM ${RUNTIME_IMAGE:-registry.access.redhat.com/ubi9/openjdk-17:1.21-2}

ENV LANGUAGE='en_US:en' LANG='en_US.UTF-8' 

# We make four distinct layers so if there are application changes, the library layers can be re-used
COPY --from=builder --chown=185 /home/kogito/serverless-workflow-project/target/quarkus-app/lib/ /deployments/lib/
COPY --from=builder --chown=185 /home/kogito/serverless-workflow-project/target/quarkus-app/*.jar /deployments/
COPY --from=builder --chown=185 /home/kogito/serverless-workflow-project/target/quarkus-app/app/ /deployments/app/
COPY --from=builder --chown=185 /home/kogito/serverless-workflow-project/target/quarkus-app/quarkus/ /deployments/quarkus/

EXPOSE 8080
USER 185

# Disable Jolokia agent
ENV AB_JOLOKIA_OFF=""

ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
ENV JAVA_APP_JAR="/deployments/quarkus-run.jar"

ENTRYPOINT [ "/opt/jboss/container/java/run/run-java.sh" ]
