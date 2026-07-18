package com.github.mdeluise.plantit.unit.component;

import com.github.mdeluise.plantit.plantinfo.identification.TrailFieldGuideIndex;
import com.github.mdeluise.plantit.plantinfo.identification.TrailFieldGuideProfile;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for the reviewed trail field guide")
class TrailFieldGuideIndexUnitTests {

    @Test
    @DisplayName("Should use exact accepted names and synonyms without partial-name inference")
    void shouldMatchReviewedScientificIdentity() {
        final TrailFieldGuideIndex index = index();

        final TrailFieldGuideProfile poisonIvy = index.find("Rhus radicans").orElseThrow();

        Assertions.assertEquals("Toxicodendron radicans", poisonIvy.scientificName());
        Assertions.assertEquals(3, poisonIvy.lookalikes().size());
        Assertions.assertEquals("Virginia creeper", poisonIvy.lookalikes().get(0).commonName());
        Assertions.assertTrue(poisonIvy.lookalikes().stream()
                                       .allMatch(lookalike -> lookalike.sourceReference().startsWith("https://")));
        Assertions.assertTrue(index.find("Toxicodendron").isEmpty());
        Assertions.assertTrue(index.find("poison ivy").isEmpty());
    }


    @Test
    @DisplayName("Should expose bounded source-backed ecology")
    void shouldExposeReviewedEcology() {
        final TrailFieldGuideProfile poodleDog = index().find("Turricula parryi").orElseThrow();

        Assertions.assertTrue(poodleDog.ecology().matchesHabitat("recent burn scar in chaparral"));
        Assertions.assertTrue(poodleDog.ecology().containsElevation(1_500));
        Assertions.assertFalse(poodleDog.ecology().containsElevation(2_500));
        Assertions.assertEquals("USDA Forest Service", poodleDog.ecology().source());
    }


    private TrailFieldGuideIndex index() {
        return new TrailFieldGuideIndex(new ClassPathResource("trail-field-guide.json"));
    }
}
