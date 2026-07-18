package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.springframework.stereotype.Component;

/**
 * Applies small, explainable context adjustments without replacing the provider's visual score.
 */
@Component
public class PlantIdentificationContextScorer {
    private static final double REGIONAL_FLORA_ADJUSTMENT = 0.02;
    private static final int STRONG_OCCURRENCE_COUNT = 25;
    private static final int MODERATE_OCCURRENCE_COUNT = 5;
    private static final double STRONG_OCCURRENCE_ADJUSTMENT = 0.10;
    private static final double MODERATE_OCCURRENCE_ADJUSTMENT = 0.07;
    private static final double LIMITED_OCCURRENCE_ADJUSTMENT = 0.04;
    private final PlantOccurrenceEvidenceProvider occurrenceEvidenceProvider;


    public PlantIdentificationContextScorer(PlantOccurrenceEvidenceProvider occurrenceEvidenceProvider) {
        this.occurrenceEvidenceProvider = occurrenceEvidenceProvider;
    }


    public List<PlantIdentificationCandidate> rerank(List<PlantIdentificationCandidate> candidates,
                                                     PlantIdentificationContext context, String language) {
        final PlantIdentificationContext effectiveContext = context == null
                                                                 ? PlantIdentificationContext.empty() : context;
        final PlantOccurrenceSnapshot occurrences = occurrenceEvidenceProvider.findNearbySeasonalEvidence(
            effectiveContext, language);
        return candidates.stream()
                         .map(candidate -> score(candidate, effectiveContext, occurrences))
                         .sorted(Comparator.comparingDouble(PlantIdentificationCandidate::contextualScore)
                                           .reversed()
                                           .thenComparing(
                                               Comparator.comparingDouble(PlantIdentificationCandidate::confidence)
                                                         .reversed()))
                         .toList();
    }


    private PlantIdentificationCandidate score(PlantIdentificationCandidate candidate,
                                                PlantIdentificationContext context,
                                                PlantOccurrenceSnapshot occurrences) {
        final List<PlantIdentificationEvidence> evidence = new ArrayList<>();
        double adjustment = 0;
        if (candidate.project().contextual()) {
            adjustment += REGIONAL_FLORA_ADJUSTMENT;
            evidence.add(new PlantIdentificationEvidence(
                "REGIONAL_FLORA", REGIONAL_FLORA_ADJUSTMENT, "Pl@ntNet", null, null,
                candidate.project().title()
            ));
        }
        final PlantOccurrenceEvidence occurrence = occurrences.find(candidate.botanicalInfo().getSpecies());
        if (occurrence != null && occurrence.observationCount() > 0) {
            final double occurrenceAdjustment = occurrenceAdjustment(occurrence.observationCount());
            adjustment += occurrenceAdjustment;
            evidence.add(new PlantIdentificationEvidence(
                "NEARBY_SEASONAL_OCCURRENCES", occurrenceAdjustment, "iNaturalist",
                occurrences.sourceReference(), occurrence.observationCount(), monthDetail(occurrences.months())
            ));
        }
        if (context.habitat() != null && !context.habitat().isBlank()) {
            evidence.add(new PlantIdentificationEvidence(
                "HABITAT_RECORDED", 0, "Field note", null, null, context.habitat().trim()
            ));
        }
        if (context.elevationMeters() != null) {
            evidence.add(new PlantIdentificationEvidence(
                "ELEVATION_RECORDED", 0, "Device location", null, null,
                String.valueOf(Math.round(context.elevationMeters()))
            ));
        }
        final double contextualScore = Math.min(1, Math.max(0, candidate.confidence() + adjustment));
        return new PlantIdentificationCandidate(
            candidate.botanicalInfo(), candidate.confidence(), contextualScore, candidate.modelVersion(),
            candidate.project(), evidence, occurrence == null ? null : occurrence.establishmentMeans(),
            occurrence == null ? null : occurrence.establishmentPlace()
        );
    }


    private double occurrenceAdjustment(int count) {
        if (count >= STRONG_OCCURRENCE_COUNT) {
            return STRONG_OCCURRENCE_ADJUSTMENT;
        }
        if (count >= MODERATE_OCCURRENCE_COUNT) {
            return MODERATE_OCCURRENCE_ADJUSTMENT;
        }
        return LIMITED_OCCURRENCE_ADJUSTMENT;
    }


    private String monthDetail(List<Integer> months) {
        return months.stream().map(String::valueOf).reduce((left, right) -> left + "," + right).orElse("");
    }


    public static PlantIdentificationContextScorer noOp() {
        return new PlantIdentificationContextScorer((context, language) -> PlantOccurrenceSnapshot.empty());
    }
}
