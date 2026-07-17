package com.github.mdeluise.plantit.plantinfo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class INaturalistProperties {
    @Value("${inaturalist.url}")
    private String url;
    @Value("${inaturalist.enabled}")
    private boolean enabled;
    @Value("${inaturalist.preferred-place-id}")
    private int preferredPlaceId;


    public String getUrl() {
        return url;
    }


    public boolean isEnabled() {
        return enabled;
    }


    public int getPreferredPlaceId() {
        return preferredPlaceId;
    }
}
