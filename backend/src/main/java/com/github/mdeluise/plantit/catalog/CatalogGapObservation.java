package com.github.mdeluise.plantit.catalog;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

@Entity
@Table(
    name = "catalog_gap_observations",
    uniqueConstraints = @UniqueConstraint(
        name = "uk_catalog_gap_owner_type_subject",
        columnNames = {"owner_id", "issue_type", "subject_key"}
    )
)
public class CatalogGapObservation {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "owner_id", nullable = false)
    private Long ownerId;
    @Enumerated(EnumType.STRING)
    @Column(name = "issue_type", nullable = false, length = 32)
    private CatalogGapType issueType;
    @Column(name = "subject_key", nullable = false, length = 160)
    private String subjectKey;
    @Column(name = "display_subject", nullable = false, length = 160)
    private String displaySubject;
    @Column(name = "scientific_name", length = 255)
    private String scientificName;
    @Column(name = "occurrence_count", nullable = false)
    private int occurrenceCount;
    @Column(name = "first_seen_at", nullable = false)
    private Instant firstSeenAt;
    @Column(name = "last_seen_at", nullable = false)
    private Instant lastSeenAt;
    @Column(nullable = false)
    private boolean active;
    @Column(name = "resolved_at")
    private Instant resolvedAt;


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


    public CatalogGapType getIssueType() {
        return issueType;
    }


    public void setIssueType(CatalogGapType issueType) {
        this.issueType = issueType;
    }


    public String getSubjectKey() {
        return subjectKey;
    }


    public void setSubjectKey(String subjectKey) {
        this.subjectKey = subjectKey;
    }


    public String getDisplaySubject() {
        return displaySubject;
    }


    public void setDisplaySubject(String displaySubject) {
        this.displaySubject = displaySubject;
    }


    public String getScientificName() {
        return scientificName;
    }


    public void setScientificName(String scientificName) {
        this.scientificName = scientificName;
    }


    public int getOccurrenceCount() {
        return occurrenceCount;
    }


    public void setOccurrenceCount(int occurrenceCount) {
        this.occurrenceCount = occurrenceCount;
    }


    public Instant getFirstSeenAt() {
        return firstSeenAt;
    }


    public void setFirstSeenAt(Instant firstSeenAt) {
        this.firstSeenAt = firstSeenAt;
    }


    public Instant getLastSeenAt() {
        return lastSeenAt;
    }


    public void setLastSeenAt(Instant lastSeenAt) {
        this.lastSeenAt = lastSeenAt;
    }


    public boolean isActive() {
        return active;
    }


    public void setActive(boolean active) {
        this.active = active;
    }


    public Instant getResolvedAt() {
        return resolvedAt;
    }


    public void setResolvedAt(Instant resolvedAt) {
        this.resolvedAt = resolvedAt;
    }
}
