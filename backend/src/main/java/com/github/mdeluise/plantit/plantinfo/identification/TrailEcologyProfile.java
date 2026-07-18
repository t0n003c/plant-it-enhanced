package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.List;

import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;

/**
 * A small, attributable ecological range used only for positive identification evidence.
 */
public record TrailEcologyProfile(List<String> habitatKeywords, String habitatDescription,
                                  Double minimumElevationMeters, Double maximumElevationMeters,
                                  String source, String sourceReference) {

    public TrailEcologyProfile {
        habitatKeywords = habitatKeywords == null ? List.of() : List.copyOf(habitatKeywords);
    }


    public boolean matchesHabitat(String habitat) {
        final String normalizedHabitat = " " + PlantNameNormalizer.normalize(habitat) + " ";
        return habitatKeywords.stream()
                              .map(PlantNameNormalizer::normalize)
                              .filter(keyword -> !keyword.isBlank())
                              .anyMatch(keyword -> normalizedHabitat.contains(" " + keyword + " "));
    }


    public boolean containsElevation(double elevationMeters) {
        if (minimumElevationMeters == null && maximumElevationMeters == null) {
            return false;
        }
        return (minimumElevationMeters == null || elevationMeters >= minimumElevationMeters) &&
                   (maximumElevationMeters == null || elevationMeters <= maximumElevationMeters);
    }
}
