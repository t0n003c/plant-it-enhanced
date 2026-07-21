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
    @DisplayName("Should keep at least 850 trusted name queries mapped to the expected taxon")
    void shouldPassLargeTrustedNameCorpus() {
        final TrustedCommonNameIndex index = createIndex();
        final List<TrustedCommonNameIndex.TrustedNameExample> examples = index.qualityExamples();

        Assertions.assertTrue(examples.size() >= 850, "The trusted-name corpus must not shrink below 850");
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
            Map.entry("arrowleaf balsamroot", "Wyethia sagittata"),
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
        Assertions.assertEquals("Lilium", index.resolveProviderSearchTerm("lily"));
        Assertions.assertEquals("Mentha × piperita", index.resolveProviderSearchTerm("peppermint"));
        Assertions.assertEquals(
            "Daucus carota sativus", index.resolveProviderSearchTerm("garden carrot"));
        Assertions.assertEquals("Solanum tuberosum", index.resolveProviderSearchTerm("russet potato"));
        Assertions.assertEquals("Solanum melongena", index.resolveProviderSearchTerm("eggplant"));
        Assertions.assertEquals("Cucurbita pepo", index.resolveProviderSearchTerm("pumpkin"));
        Assertions.assertEquals("ging", index.resolveProviderSearchTerm("ging"));
    }


    @Test
    @DisplayName("Should provide deterministic common garden identities and photo fallbacks")
    void shouldProvideCommonGardenCoverage() {
        final TrustedCommonNameIndex index = createIndex();

        final BotanicalInfo pumpkin = index.search("pumpkin", 1).get(0);
        Assertions.assertEquals("Cucurbita pepo", pumpkin.getSpecies());
        Assertions.assertEquals("Pumpkin", pumpkin.getSearchMatchedName());
        Assertions.assertNotNull(pumpkin.getImage());
        Assertions.assertNull(pumpkin.getImage().getId());
        Assertions.assertTrue(pumpkin.getImage().getUrl().contains("101476279/medium.png"));

        final BotanicalInfo sunflower = index.search("sunflower", 1).get(0);
        Assertions.assertEquals("Helianthus annuus", sunflower.getSpecies());
        Assertions.assertNotNull(sunflower.getImage());
        Assertions.assertNull(sunflower.getImage().getId());
        Assertions.assertTrue(sunflower.getImage().getUrl().contains("323768723/medium.jpg"));

        final BotanicalInfo strawberry = index.search("strawberry", 1).get(0);
        Assertions.assertEquals("Fragaria ananassa", strawberry.getSpecies());
        Assertions.assertNotNull(strawberry.getImage());
        Assertions.assertNull(strawberry.getImage().getId());
        Assertions.assertTrue(strawberry.getImage().getUrl().contains("74966564/medium.jpg"));

        final BotanicalInfo bellPepper = index.search("bell pepper", 1).get(0);
        final BotanicalInfo thaiChili = index.search("thai chili", 1).get(0);
        Assertions.assertEquals("Bell pepper", bellPepper.getPreferredCommonName());
        Assertions.assertEquals("Thai chili", thaiChili.getPreferredCommonName());
        Assertions.assertEquals("Bell pepper", bellPepper.getCatalogVariant());
        Assertions.assertEquals("Thai chili", thaiChili.getCatalogVariant());
        Assertions.assertNotEquals(bellPepper.getImage().getUrl(), thaiChili.getImage().getUrl());

        final BotanicalInfo catGrass = index.search("cat grass", 1).get(0);
        Assertions.assertEquals("Avena sativa", catGrass.getSpecies());
        Assertions.assertEquals("Cat grass (oat grass)", catGrass.getCatalogVariant());
        Assertions.assertNotNull(catGrass.getImage());
        Assertions.assertTrue(catGrass.getImage().getUrl().contains("51273833/medium.jpg"));
    }


    @Test
    @DisplayName("Should keep cultivated carrot separate from the wild trail plant")
    void shouldDistinguishCultivatedAndWildCarrot() {
        final TrustedCommonNameIndex index = createIndex();

        final BotanicalInfo cultivated = index.search("carrot", 1).get(0);
        final BotanicalInfo wild = index.search("wild carrot", 1).get(0);

        Assertions.assertEquals("Daucus carota sativus", cultivated.getSpecies());
        Assertions.assertFalse(cultivated.getCatalogTags().contains(
            TrustedCommonNameIndex.NORTH_AMERICAN_TRAIL_TAG));
        Assertions.assertEquals("Daucus carota", wild.getSpecies());
        Assertions.assertTrue(wild.getCatalogTags().contains(
            TrustedCommonNameIndex.NORTH_AMERICAN_TRAIL_TAG));
    }


    @Test
    @DisplayName("Should rank a reviewed true-lily genus above plants that only contain lily in their name")
    void shouldRankTrueLilyFirst() {
        final BotanicalInfo lily = createIndex().search("lily", 5).get(0);

        Assertions.assertEquals("Lilium", lily.getSpecies());
        Assertions.assertEquals("Lily", lily.getSearchMatchedName());
        Assertions.assertEquals("EXACT_COMMON_NAME", lily.getSearchMatchReason());
    }


    @Test
    @DisplayName("Should distinguish the matched pepper name from the species default name")
    void shouldPreserveMatchedPepperName() {
        final TrustedCommonNameIndex index = createIndex();

        final BotanicalInfo thaiChili = index.search("thai chili", 1).get(0);
        final BotanicalInfo thaiPepper = index.search("thai pepper", 1).get(0);

        Assertions.assertEquals("Capsicum annuum", thaiChili.getSpecies());
        Assertions.assertEquals("Thai chili", thaiChili.getPreferredCommonName());
        Assertions.assertEquals("Thai chili", thaiChili.getSearchMatchedName());
        Assertions.assertEquals("Thai pepper", thaiPepper.getSearchMatchedName());
    }


    @Test
    @DisplayName("Should search every reviewed accepted scientific name directly")
    void shouldSearchAcceptedScientificNames() {
        final TrustedCommonNameIndex index = createIndex();
        final BotanicalInfo bigBluestem = index.search("big bluestem", 1).get(0);

        Assertions.assertEquals("Andropogon gerardi", bigBluestem.getSpecies());
        Assertions.assertTrue(PlantSearchScorer.score("Andropogon gerardi", bigBluestem) > 0);
        Assertions.assertEquals(
            "Andropogon gerardi", index.search("Andropogon gerardi", 1).get(0).getSpecies());
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
