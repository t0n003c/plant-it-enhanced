package com.github.mdeluise.plantit.plantinfo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class TrefleCareProperties {
    @Value("${trefle.url}")
    private String url;
    @Value("${trefle.token}")
    private String token;


    public String getUrl() {
        return url;
    }


    public String getToken() {
        return token;
    }


    public boolean isConfigured() {
        return token != null && !token.isBlank();
    }
}
