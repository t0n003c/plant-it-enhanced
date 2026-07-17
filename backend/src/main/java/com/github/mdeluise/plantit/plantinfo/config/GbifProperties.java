package com.github.mdeluise.plantit.plantinfo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class GbifProperties {
    @Value("${gbif.url}")
    private String url;
    @Value("${gbif.minimum-confidence}")
    private int minimumConfidence;


    public String getUrl() {
        return url;
    }


    public int getMinimumConfidence() {
        return minimumConfidence;
    }
}
