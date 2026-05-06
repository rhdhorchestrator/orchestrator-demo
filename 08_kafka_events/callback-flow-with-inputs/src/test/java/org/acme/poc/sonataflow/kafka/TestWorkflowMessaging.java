package org.acme.poc.sonataflow.kafka;

import java.net.URI;
import java.net.URL;
import java.time.OffsetDateTime;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import org.acme.poc.sonataflow.kafka.model.LockData;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cloudevents.core.builder.CloudEventBuilder;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.common.http.TestHTTPResource;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.kafka.InjectKafkaCompanion;
import io.quarkus.test.kafka.KafkaCompanionResource;
import io.smallrye.reactive.messaging.kafka.companion.ConsumerTask;
import io.smallrye.reactive.messaging.kafka.companion.KafkaCompanion;
import jakarta.inject.Inject;
import jakarta.ws.rs.core.MediaType;

import static io.restassured.RestAssured.given;
import static org.awaitility.Awaitility.await;
import static org.junit.jupiter.api.Assertions.assertEquals;

@QuarkusTest
@QuarkusTestResource(KafkaCompanionResource.class)
class TestWorkflowMessaging {

    @InjectKafkaCompanion
    KafkaCompanion companion;

    @TestHTTPResource("/lock-flow")
    URL workflowEndpoint;

    @Inject
    ObjectMapper mapper;

    @Test
    void testExecWorkflow() throws JsonProcessingException {
        final LockData lock = new LockData("The Kraken");
        final String lockJson = mapper.writeValueAsString(lock);
        final String lockEvent = mapper.writeValueAsString(CloudEventBuilder.v1()
                .withId(UUID.randomUUID().toString())
                .withType("lock-event")
                // The lockID is our correlation
                .withExtension("lockid", lock.getId())
                .withSource(URI.create("http://dev.local"))
                .withDataContentType(MediaType.APPLICATION_JSON)
                .withTime(OffsetDateTime.now())
                .withData(lockJson.getBytes())
                .build());

        // Wait for the workflow to be ready
        await().atMost(20, TimeUnit.SECONDS) // Wait up to 20 seconds
                .pollInterval(1, TimeUnit.SECONDS) // Check every 1 second
                .until(() -> given().when().get(workflowEndpoint.toString()).getStatusCode() == 200);

        // Send ONLY ONE message to "lock-event"
        companion.produceStrings().fromRecords(new ProducerRecord<>("lock-event", lockEvent));

        // Check if the workflow instance is there waiting for us
        await().atMost(20, TimeUnit.SECONDS).pollInterval(1, TimeUnit.SECONDS).until(() -> {
            int processCount = given().when().get(workflowEndpoint).jsonPath().getList("$").size();
            return processCount > 0;
        });

        // Consume ONLY ONE message from "notify-event"
        ConsumerTask<String, String> notifyLock = companion.consumeStrings().fromTopics("notify-event", 1);
        notifyLock.awaitCompletion();
        assertEquals(1, notifyLock.count());

        // Release the kraken!
        final String releaseEvent = mapper.writeValueAsString(CloudEventBuilder.v1()
                .withId(UUID.randomUUID().toString())
                .withType("release-event")
                .withExtension("lockid", lock.getId())
                .withSource(URI.create("http://dev.local"))
                .withDataContentType(MediaType.APPLICATION_JSON)
                .withTime(OffsetDateTime.now())
                .withData(lockJson.getBytes()).build());

        // Send ONLY ONE message to "release-event"
        companion.produceStrings().fromRecords(new ProducerRecord<>("release-event", releaseEvent));

        // Consume ONLY ONE message from "released-event"
        ConsumerTask<String, String> releasedLock = companion.consumeStrings().fromTopics("released-event", 1);
        releasedLock.awaitCompletion();

        assertEquals(1, releasedLock.count()); // Ensure only one event is consumed
    }


}
