package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.List;

/**
 * Reviewed trail context associated with one exact scientific identity or synonym.
 */
public record TrailFieldGuideProfile(String scientificName, List<String> scientificSynonyms,
                                     TrailEcologyProfile ecology, List<PlantLookalike> lookalikes) {

    public TrailFieldGuideProfile {
        scientificSynonyms = scientificSynonyms == null ? List.of() : List.copyOf(scientificSynonyms);
        lookalikes = lookalikes == null ? List.of() : List.copyOf(lookalikes);
    }
}
