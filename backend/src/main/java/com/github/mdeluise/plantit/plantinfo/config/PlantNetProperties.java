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


    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank();
    }
}
