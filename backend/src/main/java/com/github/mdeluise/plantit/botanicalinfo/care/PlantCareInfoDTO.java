package com.github.mdeluise.plantit.botanicalinfo.care;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Plant care info", description = "Represents a plant's care info.")
public class PlantCareInfoDTO {
    @Schema(description = "Light requirement")
    private Integer light;
    @Schema(description = "Humidity requirement")
    private Integer humidity;
    @Schema(description = "Required soil moisture on a 0-10 scale")
    private Integer soilHumidity;
    @Schema(description = "Minimum temperature requirement")
    private Double minTemp;
    @Schema(description = "Maximum temperature requirement")
    private Double maxTemp;
    @Schema(description = "Maximum PH requirement")
    private Double phMax;
    @Schema(description = "Minimum PH requirement")
    private Double phMin;
    @Schema(description = "Plain-language light requirement", accessMode = Schema.AccessMode.READ_ONLY)
    private CareRequirementLevel lightRequirement;
    @Schema(description = "Plain-language water requirement", accessMode = Schema.AccessMode.READ_ONLY)
    private CareRequirementLevel waterRequirement;
    @Schema(description = "Source of the care data")
    private String source;
    @Schema(description = "Identifier used by the care-data source")
    private String sourceReference;
    @Schema(description = "Last verification time for the care data")
    private Instant lastVerifiedAt;
    @Schema(description = "Are all fields null?", accessMode = Schema.AccessMode.READ_ONLY)
    private boolean allNull;
    @Schema(description = "Source, confidence, and verification date for each populated care field")
    private Map<String, CareFieldProvenance> fieldProvenance = new LinkedHashMap<>();


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


    public void setPhMin(Double phMin) {
        this.phMin = phMin;
    }


    public CareRequirementLevel getLightRequirement() {
        return lightRequirement;
    }


    public void setLightRequirement(CareRequirementLevel lightRequirement) {
        this.lightRequirement = lightRequirement;
    }


    public CareRequirementLevel getWaterRequirement() {
        return waterRequirement;
    }


    public void setWaterRequirement(CareRequirementLevel waterRequirement) {
        this.waterRequirement = waterRequirement;
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
        return allNull;
    }


    public void setAllNull(boolean allNull) {
        this.allNull = allNull;
    }


    public Map<String, CareFieldProvenance> getFieldProvenance() {
        return fieldProvenance;
    }


    public void setFieldProvenance(Map<String, CareFieldProvenance> fieldProvenance) {
        this.fieldProvenance = fieldProvenance == null
                                   ? new LinkedHashMap<>() : new LinkedHashMap<>(fieldProvenance);
    }
}
