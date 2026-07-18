package com.github.mdeluise.plantit.botanicalinfo.care;

import java.io.Serializable;
import java.time.Instant;

public class CareFieldProvenance implements Serializable {
    private String source;
    private String sourceReference;
    private Double confidence;
    private Instant verifiedAt;


    public CareFieldProvenance() {
    }


    public CareFieldProvenance(String source, String sourceReference, Double confidence, Instant verifiedAt) {
        this.source = source;
        this.sourceReference = sourceReference;
        this.confidence = confidence;
        this.verifiedAt = verifiedAt;
    }


    public String getSource() {
        return source;
    }


    public void setSource(String source) {
        this.source = source;
    }


    public String getSourceReference() {
        return sourceReference;
    }


    public void setSourceReference(String sourceReference) {
        this.sourceReference = sourceReference;
    }


    public Double getConfidence() {
        return confidence;
    }


    public void setConfidence(Double confidence) {
        this.confidence = confidence;
    }


    public Instant getVerifiedAt() {
        return verifiedAt;
    }


    public void setVerifiedAt(Instant verifiedAt) {
        this.verifiedAt = verifiedAt;
    }
}
