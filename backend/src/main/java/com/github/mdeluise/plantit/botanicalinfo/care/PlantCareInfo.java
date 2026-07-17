package com.github.mdeluise.plantit.botanicalinfo.care;

import java.io.Serializable;
import java.time.Instant;
import java.util.Objects;
import java.util.stream.Stream;

import jakarta.persistence.Embeddable;
import jakarta.persistence.Column;

@Embeddable
public class PlantCareInfo implements Serializable {
    private Integer light;
    private Integer humidity;
    @Column(name = "soil_humidity")
    private Integer soilHumidity;
    private Double minTemp;
    private Double maxTemp;
    private Double phMax;
    private Double phMin;
    @Column(name = "care_source", length = 32)
    private String source;
    @Column(name = "care_source_reference", length = 128)
    private String sourceReference;
    @Column(name = "care_last_verified_at")
    private Instant lastVerifiedAt;


    public PlantCareInfo() {
    }


    public Integer getLight() {
        return light;
    }


    public void setLight(Integer light) {
        this.light = light;
    }


    public Integer getHumidity() {
        return humidity;
    }


    public void setHumidity(Integer humidity) {
        this.humidity = humidity;
    }


    public Integer getSoilHumidity() {
        return soilHumidity;
    }


    public void setSoilHumidity(Integer soilHumidity) {
        this.soilHumidity = soilHumidity;
    }


    public Double getMinTemp() {
        return minTemp;
    }


    public void setMinTemp(Double minTemp) {
        this.minTemp = minTemp;
    }


    public Double getMaxTemp() {
        return maxTemp;
    }


    public void setMaxTemp(Double maxTemp) {
        this.maxTemp = maxTemp;
    }


    public Double getPhMax() {
        return phMax;
    }


    public void setPhMax(Double phMax) {
        this.phMax = phMax;
    }


    public Double getPhMin() {
        return phMin;
    }


    public void setPhMin(Double phMi) {
        this.phMin = phMi;
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


    public Instant getLastVerifiedAt() {
        return lastVerifiedAt;
    }


    public void setLastVerifiedAt(Instant lastVerifiedAt) {
        this.lastVerifiedAt = lastVerifiedAt;
    }


    public boolean isAllNull() {
        return Stream.of(light, humidity, soilHumidity, minTemp, maxTemp, phMin, phMax).allMatch(Objects::isNull);
    }
}
