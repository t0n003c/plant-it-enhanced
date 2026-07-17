package com.github.mdeluise.plantit.botanicalinfo;

import java.io.Serializable;
import java.util.Objects;

import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

@Embeddable
public class BotanicalCommonName implements Serializable {
    @Column(name = "common_name_value", nullable = false, length = 255)
    private String name;
    @Column(name = "normalized_name", nullable = false, length = 255)
    private String normalizedName;
    @Column(name = "language_code", length = 16)
    private String language;
    @Column(name = "region_code", length = 16)
    private String region;
    @Column(name = "is_preferred", nullable = false)
    private boolean preferred;
    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 32)
    private BotanicalInfoCreator source;


    public BotanicalCommonName() {
    }


    public BotanicalCommonName(String name, String language, String region, boolean preferred,
                               BotanicalInfoCreator source) {
        setName(name);
        this.language = language;
        this.region = region;
        this.preferred = preferred;
        this.source = source;
    }


    public String getName() {
        return name;
    }


    public void setName(String name) {
        this.name = name;
        this.normalizedName = PlantNameNormalizer.normalize(name);
    }


    public String getNormalizedName() {
        return normalizedName;
    }


    public void setNormalizedName(String normalizedName) {
        this.normalizedName = normalizedName;
    }


    public String getLanguage() {
        return language;
    }


    public void setLanguage(String language) {
        this.language = language;
    }


    public String getRegion() {
        return region;
    }


    public void setRegion(String region) {
        this.region = region;
    }


    public boolean isPreferred() {
        return preferred;
    }


    public void setPreferred(boolean preferred) {
        this.preferred = preferred;
    }


    public BotanicalInfoCreator getSource() {
        return source;
    }


    public void setSource(BotanicalInfoCreator source) {
        this.source = source;
    }


    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        final BotanicalCommonName that = (BotanicalCommonName) o;
        return Objects.equals(normalizedName, that.normalizedName) && Objects.equals(language, that.language) &&
                   Objects.equals(region, that.region) && source == that.source;
    }


    @Override
    public int hashCode() {
        return Objects.hash(normalizedName, language, region, source);
    }
}
