package com.github.mdeluise.plantit.hike;

import java.io.Serializable;
import java.time.Instant;

import com.github.mdeluise.plantit.authentication.User;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import org.hibernate.validator.constraints.Length;

@Entity
@Table(name = "hike_sessions")
public class HikeSession implements Serializable {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
    @NotNull
    @ManyToOne
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;
    @NotNull
    @Length(max = 120)
    private String name;
    @NotNull
    private Instant startedAt;
    private Instant endedAt;
    @Length(max = 1000)
    private String notes;
    @Length(max = 64)
    private String clientReference;
    @NotNull
    private Instant createdAt;
    @NotNull
    private Instant updatedAt;


    @PrePersist
    public void setCreationDefaults() {
        final Instant now = Instant.now();
        if (startedAt == null) {
            startedAt = now;
        }
        if (createdAt == null) {
            createdAt = now;
        }
        updatedAt = now;
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
