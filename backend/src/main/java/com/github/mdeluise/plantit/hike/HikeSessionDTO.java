package com.github.mdeluise.plantit.hike;

import java.time.Instant;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "HikeSession", description = "A named field outing that groups plant observations.")
public class HikeSessionDTO {
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Long id;
    private String name;
    private Instant startedAt;
    private Instant endedAt;
    private String notes;
    private String clientReference;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Long observationCount;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Instant createdAt;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Instant updatedAt;


    public Long getId() {
        return id;
    }


    public void setId(Long id) {
        this.id = id;
    }


    public String getName() {
        return name;
    }


    public void setName(String name) {
        this.name = name;
    }


    public Instant getStartedAt() {
        return startedAt;
    }


    public void setStartedAt(Instant startedAt) {
        this.startedAt = startedAt;
    }


    public Instant getEndedAt() {
        return endedAt;
    }


    public void setEndedAt(Instant endedAt) {
        this.endedAt = endedAt;
    }


    public String getNotes() {
        return notes;
    }


    public void setNotes(String notes) {
        this.notes = notes;
    }


    public String getClientReference() {
        return clientReference;
    }


    public void setClientReference(String clientReference) {
        this.clientReference = clientReference;
    }


    public Long getObservationCount() {
        return observationCount;
    }


    public void setObservationCount(Long observationCount) {
        this.observationCount = observationCount;
    }


    public Instant getCreatedAt() {
        return createdAt;
    }


    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }


    public Instant getUpdatedAt() {
        return updatedAt;
    }


    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
