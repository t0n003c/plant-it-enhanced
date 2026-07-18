package com.github.mdeluise.plantit.plantinfo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PlantNetProperties {
    @Value("${plantnet.url}")
    private String url;
    @Value("${plantnet.api-key}")
    private String apiKey;
    @Value("${plantnet.maximum-results}")
    private int maximumResults;
    @Value("${plantnet.minimum-confidence}")
    private double minimumConfidence;
    @Value("${plantnet.location-project-enabled:true}")
    private boolean locationProjectEnabled;
    @Value("${plantnet.location-precision-degrees:0.5}")
    private double locationPrecisionDegrees;


    public String getUrl() {
        return url;
    }


    public String getApiKey() {
        return apiKey;
    }


    public int getMaximumResults() {
        return maximumResults;
    }


    public double getMinimumConfidence() {
        return minimumConfidence;
    }


    public boolean isLocationProjectEnabled() {
        return locationProjectEnabled;
    }


    public double getLocationPrecisionDegrees() {
        return locationPrecisionDegrees;
    }


    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank();
    }
}
