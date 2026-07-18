package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.List;
import java.util.Map;

import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;

public record PlantOccurrenceSnapshot(Map<String, PlantOccurrenceEvidence> evidenceByScientificName,
                                      String sourceReference, List<Integer> months) {

    public PlantOccurrenceSnapshot {
        evidenceByScientificName = evidenceByScientificName == null
                                       ? Map.of() : Map.copyOf(evidenceByScientificName);
        months = months == null ? List.of() : List.copyOf(months);
    }


    public static PlantOccurrenceSnapshot empty() {
        return new PlantOccurrenceSnapshot(Map.of(), null, List.of());
    }


    public PlantOccurrenceEvidence find(String scientificName) {
        return evidenceByScientificName.get(PlantNameNormalizer.normalize(scientificName));
    }
}
