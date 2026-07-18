package com.github.mdeluise.plantit.plantinfo.identification;

public record PlantNetProject(String id, String title, boolean contextual) {

    public static PlantNetProject world() {
        return new PlantNetProject("all", null, false);
    }
}
