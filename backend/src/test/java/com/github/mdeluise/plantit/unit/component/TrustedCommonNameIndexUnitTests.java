package com.github.mdeluise.plantit.unit.component;

import java.util.List;
import java.util.Map;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchScorer;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for the trusted everyday-name index")
class TrustedCommonNameIndexUnitTests {

    @Test
    @DisplayName("Should keep at least 625 trusted name queries mapped to the expected taxon")
    void shouldPassLargeTrustedNameCorpus() {
        final TrustedCommonNameIndex index = createIndex();
        final List<TrustedCommonNameIndex.TrustedNameExample> examples = index.qualityExamples();

        Assertions.assertTrue(examples.size() >= 625, "The trusted-name corpus must not shrink below 625");
        for (TrustedCommonNameIndex.TrustedNameExample example : examples) {
            final List<BotanicalInfo> result = index.search(example.query(), 1);
            Assertions.assertFalse(result.isEmpty(), "No trusted result for " + example.query());
            Assertions.assertEquals(
                example.scientificName(), result.get(0).getSpecies(),
                "Unexpected trusted result for " + example.query()
            );
        }
    }


    @Test
    @DisplayName("Should recognize representative North American trail plants")
    void shouldRecognizeRepresentativeTrailPlants() {
        final TrustedCommonNameIndex index = createIndex();
        final Map<String, String> expectedByEverydayName = Map.ofEntries(
            Map.entry("white trillium", "Trillium grandiflorum"),
            Map.entry("jack-in-the-pulpit", "Arisaema triphyllum"),
            Map.entry("little bluestem", "Schizachyrium scoparium"),
            Map.entry("ostrich fern", "Matteuccia struthiopteris"),
            Map.entry("mountain laurel", "Kalmia latifolia"),
            Map.entry("poison ivy", "Toxicodendron radicans"),
            Map.entry("poison hemlock", "Conium maculatum"),
            Map.entry("giant hogweed", "Heracleum mantegazzianum"),
            Map.entry("cow parsnip", "Heracleum maximum"),
            Map.entry("poodle dog bush", "Eriodictyon parryi"),
            Map.entry("sugar maple", "Acer saccharum"),
            Map.entry("Douglas fir", "Pseudotsuga menziesii"),
            Map.entry("coast redwood", "Sequoia sempervirens"),
            Map.entry("California poppy", "Eschscholzia californica"),
            Map.entry("arrowleaf balsamroot", "Balsamorhiza sagittata"),
            Map.entry("bog blueberry", "Vaccinium uliginosum")
        );

        expectedByEverydayName.forEach((query, expectedScientificName) -> {
            final BotanicalInfo result = index.search(query, 1).get(0);
            Assertions.assertEquals(expectedScientificName, result.getSpecies());
            Assertions.assertTrue(result.getCatalogTags().contains(
                TrustedCommonNameIndex.NORTH_AMERICAN_TRAIL_TAG));
        });
    }


    @Test
    @DisplayName("Should carry trail safety metadata onto photo-identification taxa")
    void shouldApplyTrailSafetyMetadataToIdentifiedTaxon() {
        final BotanicalInfo poisonIvy = new BotanicalInfo();
        poisonIvy.setSpecies("Rhus radicans");

        createIndex().applyCatalogMetadata(poisonIvy);

        Assertions.assertTrue(poisonIvy.getCatalogTags().contains(
            TrustedCommonNameIndex.NORTH_AMERICAN_TRAIL_TAG));
        Assertions.assertTrue(poisonIvy.getCatalogTags().contains(
            TrustedCommonNameIndex.CONTACT_HAZARD_TAG));
    }


    @Test
    @DisplayName("Should resolve exact everyday aliases for provider enrichment")
    void shouldResolveExactProviderSearchTerms() {
        final TrustedCommonNameIndex index = createIndex();

        Assertions.assertEquals("Coriandrum sativum", index.resolveProviderSearchTerm("CILANTRO"));
        Assertions.assertEquals("Zingiber officinale", index.resolveProviderSearchTerm("ginger-root"));
        Assertions.assertEquals("Brassica oleracea", index.resolveProviderSearchTerm("kale"));
        Assertions.assertEquals("Capsicum annuum", index.resolveProviderSearchTerm("Thai pepper"));
        Assertions.assertEquals("ging", index.resolveProviderSearchTerm("ging"));
    }


    @Test
    @DisplayName("Should reject a misleading word-fragment match")
    void shouldRejectMisleadingPrefix() {
        final BotanicalInfo rosemary = new BotanicalInfo();
        rosemary.setSpecies("Salvia rosmarinus");
        rosemary.getCommonNames().add(new BotanicalCommonName(
            "Rosemary", "en", null, true, BotanicalInfoCreator.INATURALIST));

        Assertions.assertFalse(PlantSearchScorer.evaluate("rose", rosemary).isRelevant());
        Assertions.assertEquals("Rosa chinensis", createIndex().search("rose", 1).get(0).getSpecies());
    }


    private TrustedCommonNameIndex createIndex() {
        return new TrustedCommonNameIndex(new ClassPathResource("trusted-common-names.json"));
    }
}
