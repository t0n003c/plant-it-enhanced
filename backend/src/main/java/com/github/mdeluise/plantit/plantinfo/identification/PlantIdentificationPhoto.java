package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.Locale;

import org.springframework.web.multipart.MultipartFile;

public record PlantIdentificationPhoto(MultipartFile image, String organ) {
    public String normalizedOrgan() {
        if (organ == null || organ.isBlank()) {
            return "auto";
        }
        final String normalized = organ.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case "leaf", "flower", "fruit", "bark", "auto" -> normalized;
            default -> "auto";
        };
    }
}
