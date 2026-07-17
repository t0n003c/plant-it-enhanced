package com.github.mdeluise.plantit.plantinfo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PlantSearchProperties {
    @Value("${plant-search.locale}")
    private String locale;
    @Value("${plant-search.region}")
    private String region;
    @Value("${plant-search.user-agent}")
    private String userAgent;


    public String getLocale() {
        return locale;
    }


    public String getRegion() {
        return region;
    }


    public String getUserAgent() {
        return userAgent;
    }
}
