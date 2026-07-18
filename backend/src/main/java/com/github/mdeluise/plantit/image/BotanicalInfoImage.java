package com.github.mdeluise.plantit.image;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Transient;

@Entity
@DiscriminatorValue("1")
public class BotanicalInfoImage extends EntityImageImpl {
    @OneToOne(cascade = {CascadeType.MERGE, CascadeType.PERSIST, CascadeType.REFRESH})
    @JoinColumn(name = "botanical_info_entity_id")
    private BotanicalInfo target;
    @Transient
    private byte[] content;
    @Column(name = "fallback_url", length = 255)
    private String fallbackUrl;
    @Column(name = "source_provider", length = 32)
    private String source;
    @Column(name = "source_url", length = 512)
    private String sourceUrl;
    @Column(name = "license_code", length = 64)
    private String licenseCode;
    @Column(name = "attribution", length = 1024)
    private String attribution;


    public BotanicalInfoImage() {
        super();
    }


    public BotanicalInfo getTarget() {
        return target;
    }


    public void setTarget(BotanicalInfo target) {
        this.target = target;
    }


    public byte[] getContent() {
        return content;
    }


    public void setContent(byte[] content) {
        this.content = content;
    }


    public String getFallbackUrl() {
        return fallbackUrl;
    }


    public void setFallbackUrl(String fallbackUrl) {
        this.fallbackUrl = fallbackUrl;
    }


    public String getSource() {
        return source;
    }


    public void setSource(String source) {
        this.source = source;
    }


    public String getSourceUrl() {
        return sourceUrl;
    }


    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }


    public String getLicenseCode() {
        return licenseCode;
    }


    public void setLicenseCode(String licenseCode) {
        this.licenseCode = licenseCode;
    }


    public String getAttribution() {
        return attribution;
    }


    public void setAttribution(String attribution) {
        this.attribution = attribution;
    }


    public void copyMetadataFrom(BotanicalInfoImage sourceImage) {
        if (sourceImage == null) {
            return;
        }
        fallbackUrl = sourceImage.getFallbackUrl();
        source = sourceImage.getSource();
        sourceUrl = sourceImage.getSourceUrl();
        licenseCode = sourceImage.getLicenseCode();
        attribution = sourceImage.getAttribution();
    }


    public void fillMissingMetadataFrom(BotanicalInfoImage sourceImage) {
        if (sourceImage == null) {
            return;
        }
        fallbackUrl = fallback(fallbackUrl, sourceImage.getFallbackUrl());
        source = fallback(source, sourceImage.getSource());
        sourceUrl = fallback(sourceUrl, sourceImage.getSourceUrl());
        licenseCode = fallback(licenseCode, sourceImage.getLicenseCode());
        attribution = fallback(attribution, sourceImage.getAttribution());
    }


    private String fallback(String current, String replacement) {
        return current == null || current.isBlank() ? replacement : current;
    }
}
