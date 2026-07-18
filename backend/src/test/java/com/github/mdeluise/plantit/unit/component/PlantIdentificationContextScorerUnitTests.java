package com.github.mdeluise.plantit.unit.component;

import java.time.Instant;
import java.util.List;
import java.util.Map;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationCandidate;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationContext;
import com.github.mdeluise.plantit.plantinfo.identification.PlantIdentificationContextScorer;
import com.github.mdeluise.plantit.plantinfo.identification.PlantNetProject;
import com.github.mdeluise.plantit.plantinfo.identification.PlantOccurrenceEvidence;
import com.github.mdeluise.plantit.plantinfo.identification.PlantOccurrenceSnapshot;
import com.github.mdeluise.plantit.plantinfo.identification.TrailFieldGuideIndex;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for contextual identification scoring")
class PlantIdentificationContextScorerUnitTests {

    @Test
    @DisplayName("Should rerank with bounded nearby seasonal evidence and retain the visual score")
    void shouldRerankWithAttributableEvidence() {
        final PlantIdentificationContextScorer scorer = new PlantIdentificationContextScorer(
            (context, language) -> new PlantOccurrenceSnapshot(
                Map.of("candidate b", new PlantOccurrenceEvidence(42, "native", "United States")),
                "https://api.inaturalist.org/v1/observations/species_counts?lat=42.0&lng=-87.5",
                List.of(6, 7, 8)
            ));
        final PlantIdentificationContext context = new PlantIdentificationContext(
            41.88, -87.63, 181.2, "woodland edge", Instant.parse("2026-07-18T12:00:00Z"), "US");
        final PlantNetProject project = new PlantNetProject(
            "k-northern-america", "Northern America", true);

        final List<PlantIdentificationCandidate> result = scorer.rerank(List.of(
            candidate("Candidate a", 0.90, project),
            candidate("Candidate b", 0.84, project)
        ), context, "en");

        Assertions.assertEquals("Candidate b", result.get(0).botanicalInfo().getSpecies());
        Assertions.assertEquals(0.84, result.get(0).confidence());
        Assertions.assertEquals(0.96, result.get(0).contextualScore(), 0.0001);
        Assertions.assertEquals("native", result.get(0).establishmentMeans());
        Assertions.assertEquals("United States", result.get(0).establishmentPlace());
        Assertions.assertTrue(result.get(0).evidence().stream()
                                    .anyMatch(evidence -> "NEARBY_SEASONAL_OCCURRENCES".equals(evidence.code())));
        Assertions.assertTrue(result.get(0).evidence().stream()
                                    .anyMatch(evidence -> "HABITAT_RECORDED".equals(evidence.code())
                                        && evidence.adjustment() == 0));
        Assertions.assertTrue(result.get(0).evidence().stream()
                                    .anyMatch(evidence -> "ELEVATION_RECORDED".equals(evidence.code())
                                        && evidence.adjustment() == 0));
    }


    @Test
    @DisplayName("Should add only positive source-backed habitat and elevation evidence")
    void shouldUseReviewedEcologyWithoutNegativeScoring() {
        final TrailFieldGuideIndex fieldGuide = new TrailFieldGuideIndex(
            new ClassPathResource("trail-field-guide.json"));
        final PlantIdentificationContextScorer scorer = new PlantIdentificationContextScorer(
            (context, language) -> PlantOccurrenceSnapshot.empty(), fieldGuide);
        final PlantIdentificationContext matchingContext = new PlantIdentificationContext(
            36.6, -118.7, 1_500.0, "shaded stream bank", Instant.parse("2026-07-18T12:00:00Z"), "US");
        final PlantNetProject project = new PlantNetProject("all", "World flora", false);

        final PlantIdentificationCandidate matching = scorer.rerank(
            List.of(candidate("Urtica dioica", 0.80, project)), matchingContext, "en").get(0);

        Assertions.assertEquals(0.85, matching.contextualScore(), 0.0001);
        Assertions.assertTrue(matching.evidence().stream().anyMatch(
            evidence -> "HABITAT_MATCH".equals(evidence.code()) && evidence.adjustment() == 0.03));
        Assertions.assertTrue(matching.evidence().stream().anyMatch(
            evidence -> "ELEVATION_MATCH".equals(evidence.code()) && evidence.adjustment() == 0.02));
        Assertions.assertTrue(matching.evidence().stream()
                                      .filter(evidence -> evidence.adjustment() > 0)
                                      .allMatch(evidence -> evidence.sourceReference() != null));

        final PlantIdentificationContext unmatchedContext = new PlantIdentificationContext(
            null, null, 3_500.0, "desert dune", null, null);
        final PlantIdentificationCandidate unmatched = scorer.rerank(
            List.of(candidate("Urtica dioica", 0.80, project)), unmatchedContext, "en").get(0);

        Assertions.assertEquals(0.80, unmatched.contextualScore(), 0.0001);
        Assertions.assertTrue(unmatched.evidence().stream()
                                       .anyMatch(evidence -> "HABITAT_RECORDED".equals(evidence.code())));
        Assertions.assertTrue(unmatched.evidence().stream()
                                       .anyMatch(evidence -> "ELEVATION_RECORDED".equals(evidence.code())));

        final PlantIdentificationCandidate poisonIvy = scorer.rerank(
            List.of(candidate("Rhus radicans", 0.80, project)), PlantIdentificationContext.empty(), "en").get(0);
        Assertions.assertEquals(3, poisonIvy.reviewedLookalikes().size());
        Assertions.assertEquals("Virginia creeper", poisonIvy.reviewedLookalikes().get(0).commonName());
    }


    private PlantIdentificationCandidate candidate(String scientificName, double confidence,
                                                    PlantNetProject project) {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies(scientificName);
        return new PlantIdentificationCandidate(botanicalInfo, confidence, "model", project);
    }
}
