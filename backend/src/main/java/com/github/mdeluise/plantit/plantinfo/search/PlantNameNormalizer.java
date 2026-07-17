package com.github.mdeluise.plantit.plantinfo.search;

import java.text.Normalizer;
import java.util.Locale;

public final class PlantNameNormalizer {
    private PlantNameNormalizer() {
    }


    public static String normalize(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        final String withoutAccents = Normalizer.normalize(value, Normalizer.Form.NFD)
                                                 .replaceAll("\\p{M}", "");
        return withoutAccents.toLowerCase(Locale.ROOT)
                             .replaceAll("[^a-z0-9]+", " ")
                             .trim()
                             .replaceAll("\\s+", " ");
    }
}
