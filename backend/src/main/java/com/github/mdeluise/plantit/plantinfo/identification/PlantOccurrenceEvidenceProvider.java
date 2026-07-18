package com.github.mdeluise.plantit.plantinfo.identification;

public interface PlantOccurrenceEvidenceProvider {
    PlantOccurrenceSnapshot findNearbySeasonalEvidence(PlantIdentificationContext context, String language);
}
