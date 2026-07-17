package com.github.mdeluise.plantit.botanicalinfo;

public class BotanicalCommonNameDTO {
    private String name;
    private String language;
    private String region;
    private boolean preferred;
    private String source;


    public String getName() {
        return name;
    }


    public void setName(String name) {
        this.name = name;
    }


    public String getLanguage() {
        return language;
    }


    public void setLanguage(String language) {
        this.language = language;
    }


    public String getRegion() {
        return region;
    }


    public void setRegion(String region) {
        this.region = region;
    }


    public boolean isPreferred() {
        return preferred;
    }


    public void setPreferred(boolean preferred) {
        this.preferred = preferred;
    }


    public String getSource() {
        return source;
    }


    public void setSource(String source) {
        this.source = source;
    }
}
