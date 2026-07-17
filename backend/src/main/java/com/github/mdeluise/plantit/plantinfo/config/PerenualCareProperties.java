package com.github.mdeluise.plantit.plantinfo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class PerenualCareProperties {
    @Value("${perenual.url}")
    private String url;
    @Value("${perenual.api-key}")
    private String apiKey;


    public String getUrl() {
        return url;
    }


    public String getApiKey() {
        return apiKey;
    }


    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank();
    }
}
