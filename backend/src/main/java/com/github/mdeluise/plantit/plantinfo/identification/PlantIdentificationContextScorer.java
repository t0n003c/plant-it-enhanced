package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
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
    private static final double REVIEWED_HABITAT_ADJUSTMENT = 0.03;
    private static final double REVIEWED_ELEVATION_ADJUSTMENT = 0.02;
    private final PlantOccurrenceEvidenceProvider occurrenceEvidenceProvider;
    private final TrailFieldGuideIndex trailFieldGuideIndex;


    public PlantIdentificationContextScorer(PlantOccurrenceEvidenceProvider occurrenceEvidenceProvider) {
        this(occurrenceEvidenceProvider, TrailFieldGuideIndex.empty());
    }


    @Autowired
    public PlantIdentificationContextScorer(PlantOccurrenceEvidenceProvider occurrenceEvidenceProvider,
                                             TrailFieldGuideIndex trailFieldGuideIndex) {
        this.occurrenceEvidenceProvider = occurrenceEvidenceProvider;
        this.trailFieldGuideIndex = trailFieldGuideIndex;
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
        final List<PlantIdentificationEvidence> evidence = new ArrayList<>(candidate.evidence());
        final Optional<TrailFieldGuideProfile> fieldGuideProfile = trailFieldGuideIndex.find(
            candidate.botanicalInfo().getSpecies());
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
        adjustment += habitatEvidence(context, fieldGuideProfile, evidence);
        adjustment += elevationEvidence(context, fieldGuideProfile, evidence);
        final double contextualScore = Math.min(1, Math.max(0, candidate.confidence() + adjustment));
        return new PlantIdentificationCandidate(
            candidate.botanicalInfo(), candidate.confidence(), contextualScore, candidate.modelVersion(),
            candidate.project(), evidence, occurrence == null ? null : occurrence.establishmentMeans(),
            occurrence == null ? null : occurrence.establishmentPlace(),
            fieldGuideProfile.map(TrailFieldGuideProfile::lookalikes).orElse(candidate.reviewedLookalikes())
        );
    }


    private double habitatEvidence(PlantIdentificationContext context,
                                   Optional<TrailFieldGuideProfile> fieldGuideProfile,
                                   List<PlantIdentificationEvidence> evidence) {
        if (context.habitat() == null || context.habitat().isBlank()) {
            return 0;
        }
        final Optional<TrailEcologyProfile> matchingEcology = fieldGuideProfile
            .map(TrailFieldGuideProfile::ecology)
            .filter(ecology -> ecology.matchesHabitat(context.habitat()));
        if (matchingEcology.isPresent()) {
            final TrailEcologyProfile ecology = matchingEcology.get();
            evidence.add(new PlantIdentificationEvidence(
                "HABITAT_MATCH", REVIEWED_HABITAT_ADJUSTMENT, ecology.source(), ecology.sourceReference(), null,
                ecology.habitatDescription()
            ));
            return REVIEWED_HABITAT_ADJUSTMENT;
        }
        evidence.add(new PlantIdentificationEvidence(
            "HABITAT_RECORDED", 0, "Field note", null, null, context.habitat().trim()
        ));
        return 0;
    }


    private double elevationEvidence(PlantIdentificationContext context,
                                     Optional<TrailFieldGuideProfile> fieldGuideProfile,
                                     List<PlantIdentificationEvidence> evidence) {
        if (context.elevationMeters() == null) {
            return 0;
        }
        final Optional<TrailEcologyProfile> matchingEcology = fieldGuideProfile
            .map(TrailFieldGuideProfile::ecology)
            .filter(ecology -> ecology.containsElevation(context.elevationMeters()));
        if (matchingEcology.isPresent()) {
            final TrailEcologyProfile ecology = matchingEcology.get();
            evidence.add(new PlantIdentificationEvidence(
                "ELEVATION_MATCH", REVIEWED_ELEVATION_ADJUSTMENT, ecology.source(), ecology.sourceReference(), null,
                elevationRange(ecology)
            ));
            return REVIEWED_ELEVATION_ADJUSTMENT;
        }
        evidence.add(new PlantIdentificationEvidence(
            "ELEVATION_RECORDED", 0, "Device location", null, null,
            String.valueOf(Math.round(context.elevationMeters()))
        ));
        return 0;
    }


    private String elevationRange(TrailEcologyProfile ecology) {
        if (ecology.minimumElevationMeters() != null && ecology.maximumElevationMeters() != null) {
            return Math.round(ecology.minimumElevationMeters()) + "–" +
                       Math.round(ecology.maximumElevationMeters());
        }
        if (ecology.minimumElevationMeters() != null) {
            return Math.round(ecology.minimumElevationMeters()) + "+";
        }
        return "≤" + Math.round(ecology.maximumElevationMeters());
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
