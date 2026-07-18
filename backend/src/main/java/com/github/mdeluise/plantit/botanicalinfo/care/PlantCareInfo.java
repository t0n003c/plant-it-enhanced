package com.github.mdeluise.plantit.botanicalinfo.care;

import java.io.Serializable;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Stream;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Embeddable;

@Embeddable
public class PlantCareInfo implements Serializable {
    public static final String LIGHT_FIELD = "light";
    public static final String HUMIDITY_FIELD = "humidity";
    public static final String SOIL_HUMIDITY_FIELD = "soilHumidity";
    public static final String MIN_TEMP_FIELD = "minTemp";
    public static final String MAX_TEMP_FIELD = "maxTemp";
    public static final String PH_MIN_FIELD = "phMin";
    public static final String PH_MAX_FIELD = "phMax";
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
    @Convert(converter = CareFieldProvenanceMapConverter.class)
    @Column(name = "care_field_provenance", columnDefinition = "text")
    private Map<String, CareFieldProvenance> fieldProvenance = new LinkedHashMap<>();

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


    public Map<String, CareFieldProvenance> getFieldProvenance() {
        if (fieldProvenance == null) {
            fieldProvenance = new LinkedHashMap<>();
        }
        return fieldProvenance;
    }


    public void setFieldProvenance(Map<String, CareFieldProvenance> fieldProvenance) {
        this.fieldProvenance = fieldProvenance == null
                                   ? new LinkedHashMap<>() : new LinkedHashMap<>(fieldProvenance);
    }


    public void attributePopulatedFields(String dataSource, String reference,
                                         Double confidence, Instant verifiedAt) {
        final CareFieldProvenance provenance = new CareFieldProvenance(
            dataSource, reference, confidence, verifiedAt);
        attributeIfPresent(LIGHT_FIELD, light, provenance);
        attributeIfPresent(HUMIDITY_FIELD, humidity, provenance);
        attributeIfPresent(SOIL_HUMIDITY_FIELD, soilHumidity, provenance);
        attributeIfPresent(MIN_TEMP_FIELD, minTemp, provenance);
        attributeIfPresent(MAX_TEMP_FIELD, maxTemp, provenance);
        attributeIfPresent(PH_MIN_FIELD, phMin, provenance);
        attributeIfPresent(PH_MAX_FIELD, phMax, provenance);
    }


    public void fillMissingFieldsFrom(PlantCareInfo sourceInfo) {
        if (sourceInfo == null) {
            return;
        }
        light = fill(LIGHT_FIELD, light, sourceInfo.light, sourceInfo);
        humidity = fill(HUMIDITY_FIELD, humidity, sourceInfo.humidity, sourceInfo);
        soilHumidity = fill(SOIL_HUMIDITY_FIELD, soilHumidity, sourceInfo.soilHumidity, sourceInfo);
        minTemp = fill(MIN_TEMP_FIELD, minTemp, sourceInfo.minTemp, sourceInfo);
        maxTemp = fill(MAX_TEMP_FIELD, maxTemp, sourceInfo.maxTemp, sourceInfo);
        phMin = fill(PH_MIN_FIELD, phMin, sourceInfo.phMin, sourceInfo);
        phMax = fill(PH_MAX_FIELD, phMax, sourceInfo.phMax, sourceInfo);
        updateLegacySummary();
    }


    public PlantCareInfo copy() {
        final PlantCareInfo result = new PlantCareInfo();
        result.light = light;
        result.humidity = humidity;
        result.soilHumidity = soilHumidity;
        result.minTemp = minTemp;
        result.maxTemp = maxTemp;
        result.phMin = phMin;
        result.phMax = phMax;
        result.source = source;
        result.sourceReference = sourceReference;
        result.lastVerifiedAt = lastVerifiedAt;
        result.setFieldProvenance(getFieldProvenance());
        return result;
    }


    public boolean isAllNull() {
        return Stream.of(light, humidity, soilHumidity, minTemp, maxTemp, phMin, phMax).allMatch(Objects::isNull);
    }


    private void attributeIfPresent(String field, Object value, CareFieldProvenance provenance) {
        if (value != null) {
            getFieldProvenance().put(field, provenance);
        }
    }


    private <T> T fill(String field, T currentValue, T incomingValue, PlantCareInfo incoming) {
        if (currentValue != null || incomingValue == null) {
            return currentValue;
        }
        final CareFieldProvenance incomingProvenance = incoming.getFieldProvenance().get(field);
        getFieldProvenance().put(field, incomingProvenance == null
            ? new CareFieldProvenance(incoming.source, incoming.sourceReference, null, incoming.lastVerifiedAt)
            : incomingProvenance);
        return incomingValue;
    }


    private void updateLegacySummary() {
        if (getFieldProvenance().isEmpty()) {
            return;
        }
        final Set<String> sources = getFieldProvenance().values().stream()
                                           .map(CareFieldProvenance::getSource)
                                           .filter(Objects::nonNull)
                                           .collect(java.util.stream.Collectors.toSet());
        source = sources.size() == 1 ? sources.iterator().next() : "MULTIPLE";
        sourceReference = sources.size() == 1
                              ? getFieldProvenance().values().stream()
                                    .map(CareFieldProvenance::getSourceReference)
                                    .filter(Objects::nonNull)
                                    .findFirst().orElse(null)
                              : null;
        lastVerifiedAt = getFieldProvenance().values().stream()
                               .map(CareFieldProvenance::getVerifiedAt)
                               .filter(Objects::nonNull)
                               .max(Instant::compareTo)
                               .orElse(lastVerifiedAt);
    }
}
