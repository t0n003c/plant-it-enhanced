package com.github.mdeluise.plantit.systeminfo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class BuildInfoService {
    private final BuildInfo buildInfo;


    public BuildInfoService(@Value("${app.version:unknown}") String version,
                            @Value("${app.build-revision:development}") String revision) {
        this.buildInfo = new BuildInfo(normalize(version, "unknown"),
                                       normalize(revision, "development"));
    }


    public BuildInfo get() {
        return buildInfo;
    }


    private static String normalize(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value.trim();
    }
}
