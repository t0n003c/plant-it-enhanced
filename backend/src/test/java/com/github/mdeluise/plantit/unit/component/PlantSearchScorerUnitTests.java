package com.github.mdeluise.plantit.unit.component;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchMatch;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchMatchReason;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchScorer;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for common-name normalization and ranking")
class PlantSearchScorerUnitTests {

    @Test
    @DisplayName("Should keep an exact accepted name ahead of a low-confidence synonym prefix")
    void shouldPreferExactAcceptedScientificName() {
        final BotanicalInfo bigBluestem = createPlant("Andropogon gerardi", "Big bluestem");
        bigBluestem.getSynonyms().add("Andropogon gerardii");

        final PlantSearchMatch match = PlantSearchScorer.evaluate("Andropogon gerardi", bigBluestem);

        Assertions.assertEquals(PlantSearchMatchReason.SCIENTIFIC_NAME, match.reason());
        Assertions.assertEquals(0.96, match.confidence());
        Assertions.assertEquals("Andropogon gerardi", match.matchedName());
        Assertions.assertTrue(match.isRelevant());
    }

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
        Assertions.assertEquals("Golden Pothos", plant.getSearchMatchedName());
    }


    @Test
    @DisplayName("Should preserve the everyday name that matched a multi-purpose species")
    void shouldPreserveMatchedEverydayName() {
        final BotanicalInfo pepper = createPlant("Capsicum annuum", "Bell pepper");
        pepper.getCommonNames().add(new BotanicalCommonName(
            "Thai pepper", "en", null, false, BotanicalInfoCreator.TRUSTED_NAME_INDEX
        ));
        pepper.getCommonNames().add(new BotanicalCommonName(
            "Thai chili", "en", null, false, BotanicalInfoCreator.TRUSTED_NAME_INDEX
        ));

        PlantSearchScorer.applyMatchMetadata("thai chili", pepper);

        Assertions.assertEquals("EXACT_COMMON_NAME", pepper.getSearchMatchReason());
        Assertions.assertEquals("Thai chili", pepper.getSearchMatchedName());
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
