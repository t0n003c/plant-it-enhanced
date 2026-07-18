package com.github.mdeluise.plantit.plantinfo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class ContextualIdentificationProperties {
    @Value("${identification.context.enabled:true}")
    private boolean enabled;
    @Value("${identification.context.occurrence-radius-km:100}")
    private int occurrenceRadiusKm;
    @Value("${identification.context.occurrence-result-limit:200}")
    private int occurrenceResultLimit;


    public boolean isEnabled() {
        return enabled;
    }


    public int getOccurrenceRadiusKm() {
        return occurrenceRadiusKm;
    }


    public int getOccurrenceResultLimit() {
        return occurrenceResultLimit;
    }
}
