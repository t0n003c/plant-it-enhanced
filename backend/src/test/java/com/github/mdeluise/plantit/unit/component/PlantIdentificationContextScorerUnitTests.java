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
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

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


    private PlantIdentificationCandidate candidate(String scientificName, double confidence,
                                                    PlantNetProject project) {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies(scientificName);
        return new PlantIdentificationCandidate(botanicalInfo, confidence, "model", project);
    }
}
