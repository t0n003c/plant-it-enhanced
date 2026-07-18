package com.github.mdeluise.plantit.observation;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Observation", description = "A wild plant encountered at a particular time and place.")
public class ObservationDTO {
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Long id;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Long ownerId;
    private Long botanicalInfoId;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private String scientificName;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private String preferredCommonName;
    private Instant observedAt;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Instant createdAt;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private Instant updatedAt;
    private String displayName;
    private String trailName;
    private String habitat;
    private String notes;
    private Double latitude;
    private Double longitude;
    private Double accuracyMeters;
    private Double elevationMeters;
    private String locationPrivacy;
    private String status;
    private Double identificationConfidence;
    private String identificationProvider;
    @Schema(accessMode = Schema.AccessMode.READ_ONLY)
    private List<String> imageIds = new ArrayList<>();


    public Long getId() {
        return id;
    }


    public void setId(Long id) {
        this.id = id;
    }


    public Long getOwnerId() {
        return ownerId;
    }


    public void setOwnerId(Long ownerId) {
        this.ownerId = ownerId;
    }


    public Long getBotanicalInfoId() {
        return botanicalInfoId;
    }


    public void setBotanicalInfoId(Long botanicalInfoId) {
        this.botanicalInfoId = botanicalInfoId;
    }


    public String getScientificName() {
        return scientificName;
    }


    public void setScientificName(String scientificName) {
        this.scientificName = scientificName;
    }


    public String getPreferredCommonName() {
        return preferredCommonName;
    }


    public void setPreferredCommonName(String preferredCommonName) {
        this.preferredCommonName = preferredCommonName;
    }


    public Instant getObservedAt() {
        return observedAt;
    }


    public void setObservedAt(Instant observedAt) {
        this.observedAt = observedAt;
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


    public String getDisplayName() {
        return displayName;
    }


    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }


    public String getTrailName() {
        return trailName;
    }


    public void setTrailName(String trailName) {
        this.trailName = trailName;
    }


    public String getHabitat() {
        return habitat;
    }


    public void setHabitat(String habitat) {
        this.habitat = habitat;
    }


    public String getNotes() {
        return notes;
    }


    public void setNotes(String notes) {
        this.notes = notes;
    }


    public Double getLatitude() {
        return latitude;
    }


    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }


    public Double getLongitude() {
        return longitude;
    }


    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }


    public Double getAccuracyMeters() {
        return accuracyMeters;
    }


    public void setAccuracyMeters(Double accuracyMeters) {
        this.accuracyMeters = accuracyMeters;
    }


    public Double getElevationMeters() {
        return elevationMeters;
    }


    public void setElevationMeters(Double elevationMeters) {
        this.elevationMeters = elevationMeters;
    }


    public String getLocationPrivacy() {
        return locationPrivacy;
    }


    public void setLocationPrivacy(String locationPrivacy) {
        this.locationPrivacy = locationPrivacy;
    }


    public String getStatus() {
        return status;
    }


    public void setStatus(String status) {
        this.status = status;
    }


    public Double getIdentificationConfidence() {
        return identificationConfidence;
    }


    public void setIdentificationConfidence(Double identificationConfidence) {
        this.identificationConfidence = identificationConfidence;
    }


    public String getIdentificationProvider() {
        return identificationProvider;
    }


    public void setIdentificationProvider(String identificationProvider) {
        this.identificationProvider = identificationProvider;
    }


    public List<String> getImageIds() {
        return imageIds;
    }


    public void setImageIds(List<String> imageIds) {
        this.imageIds = imageIds;
    }
}
