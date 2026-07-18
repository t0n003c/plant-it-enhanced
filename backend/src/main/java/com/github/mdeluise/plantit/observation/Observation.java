package com.github.mdeluise.plantit.observation;

import java.io.Serializable;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

import com.github.mdeluise.plantit.authentication.User;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.hike.HikeSession;
import com.github.mdeluise.plantit.image.ImageTarget;
import com.github.mdeluise.plantit.image.ObservationImage;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import org.hibernate.validator.constraints.Length;

@Entity
@Table(name = "observations")
public class Observation implements Serializable, ImageTarget {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
    @NotNull
    @ManyToOne
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;
    @ManyToOne
    @JoinColumn(name = "botanical_info_id")
    private BotanicalInfo botanicalInfo;
    @ManyToOne
    @JoinColumn(name = "hike_session_id")
    private HikeSession hikeSession;
    @NotNull
    private Instant observedAt;
    @NotNull
    private Instant createdAt;
    @NotNull
    private Instant updatedAt;
    @Length(max = 120)
    private String displayName;
    @Length(max = 120)
    private String trailName;
    @Length(max = 120)
    private String habitat;
    @Length(max = 8500)
    @Column(length = 8500)
    private String notes;
    private Double latitude;
    private Double longitude;
    private Double accuracyMeters;
    private Double elevationMeters;
    @NotNull
    @Enumerated(EnumType.STRING)
    private ObservationLocationPrivacy locationPrivacy;
    @NotNull
    @Enumerated(EnumType.STRING)
    private ObservationStatus status;
    private Double identificationConfidence;
    @Length(max = 40)
    private String identificationProvider;
    @Length(max = 64)
    private String clientReference;
    @NotNull
    @OneToMany(mappedBy = "target", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ObservationImage> images = new HashSet<>();


    @PrePersist
    public void setCreationDefaults() {
        final Instant now = Instant.now();
        if (observedAt == null) {
            observedAt = now;
        }
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
        if (locationPrivacy == null) {
            locationPrivacy = ObservationLocationPrivacy.PRIVATE;
        }
        if (status == null) {
            status = botanicalInfo == null ? ObservationStatus.UNIDENTIFIED : ObservationStatus.CONFIRMED;
        }
    }


    @PreUpdate
    public void touchUpdatedAt() {
        updatedAt = Instant.now();
    }


    public Long getId() {
        return id;
    }


    public void setId(Long id) {
        this.id = id;
    }


    public User getOwner() {
        return owner;
    }


    public void setOwner(User owner) {
        this.owner = owner;
    }


    public BotanicalInfo getBotanicalInfo() {
        return botanicalInfo;
    }


    public void setBotanicalInfo(BotanicalInfo botanicalInfo) {
        this.botanicalInfo = botanicalInfo;
    }


    public HikeSession getHikeSession() {
        return hikeSession;
    }


    public void setHikeSession(HikeSession hikeSession) {
        this.hikeSession = hikeSession;
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


    public ObservationLocationPrivacy getLocationPrivacy() {
        return locationPrivacy;
    }


    public void setLocationPrivacy(ObservationLocationPrivacy locationPrivacy) {
        this.locationPrivacy = locationPrivacy;
    }


    public ObservationStatus getStatus() {
        return status;
    }


    public void setStatus(ObservationStatus status) {
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


    public String getClientReference() {
        return clientReference;
    }


    public void setClientReference(String clientReference) {
        this.clientReference = clientReference;
    }


    public Set<ObservationImage> getImages() {
        return images;
    }


    public void setImages(Set<ObservationImage> images) {
        this.images = images;
    }
}
