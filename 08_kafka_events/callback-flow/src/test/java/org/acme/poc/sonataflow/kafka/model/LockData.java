package org.acme.poc.sonataflow.kafka.model;

import java.util.UUID;

public class LockData {

    private String name;
    private String id;

    public LockData(final String name) {
        this.name = name;
        this.id = UUID.randomUUID().toString();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
