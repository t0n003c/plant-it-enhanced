package com.github.mdeluise.plantit.unit.component;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchScorer;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for common-name normalization and ranking")
class PlantSearchScorerUnitTests {

    @Test
    @DisplayName("Should normalize punctuation, whitespace, case, and accents")
    void shouldNormalizePlantNames() {
        final String normalized = PlantNameNormalizer.normalize("  Mother-in-Law’s Tóngue  ");

        Assertions.assertEquals("mother in law s tongue", normalized);
    }


    @Test
    @DisplayName("Should rank a preferred common name above legacy synonyms")
    void shouldPreferStructuredCommonName() {
        final BotanicalInfo preferred = createPlant("Dracaena trifasciata", "Snake Plant");
        final BotanicalInfo legacy = new BotanicalInfo();
        legacy.setSpecies("Unrelated scientific name");
        legacy.getSynonyms().add("Snake Plant");

        Assertions.assertTrue(
            PlantSearchScorer.score("snake plant", preferred) > PlantSearchScorer.score("snake plant", legacy)
        );
    }


    @Test
    @DisplayName("Should handle token order and a small typing error")
    void shouldHandleTokenOrderAndTypingError() {
        final BotanicalInfo plant = createPlant("Epipremnum aureum", "Golden Pothos Plant");

        Assertions.assertTrue(PlantSearchScorer.score("plant golden", plant) > 0);
        Assertions.assertTrue(PlantSearchScorer.score("potohs", plant) > 0);
        Assertions.assertTrue(PlantSearchScorer.score("golden potohs plant", plant) > 0);
    }


    @Test
    @DisplayName("Should expose a human-readable match reason and confidence")
    void shouldExplainSearchMatch() {
        final BotanicalInfo plant = createPlant("Epipremnum aureum", "Golden Pothos");

        PlantSearchScorer.applyMatchMetadata("golden pothos", plant);

        Assertions.assertEquals("EXACT_COMMON_NAME", plant.getSearchMatchReason());
        Assertions.assertEquals(1.0, plant.getSearchMatchConfidence());
    }


    private BotanicalInfo createPlant(String scientificName, String commonName) {
        final BotanicalInfo plant = new BotanicalInfo();
        plant.setSpecies(scientificName);
        plant.getCommonNames().add(new BotanicalCommonName(
            commonName, "en", "US", true, BotanicalInfoCreator.INATURALIST
        ));
        return plant;
    }
}
