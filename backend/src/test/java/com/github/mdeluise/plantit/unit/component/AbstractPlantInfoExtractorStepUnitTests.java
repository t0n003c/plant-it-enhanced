package com.github.mdeluise.plantit.unit.component;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.image.BotanicalInfoImage;
import com.github.mdeluise.plantit.plantinfo.AbstractPlantInfoExtractorStep;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for plant provider enrichment")
class AbstractPlantInfoExtractorStepUnitTests {

    @Test
    @DisplayName("Should continue to the next provider when a full result page is missing an image")
    void shouldEnrichAFullResultPage() {
        final StubExtractor first = new StubExtractor(createPlant(null));
        final StubExtractor imageProvider = new StubExtractor(createPlant("https://example.org/plant.jpg"));
        first.setNext(imageProvider);

        final List<BotanicalInfo> result = first.extractPlants("plant", 1);

        Assertions.assertEquals(1, imageProvider.getCalls());
        Assertions.assertEquals("https://example.org/plant.jpg", result.get(0).getImage().getUrl());
    }


    @Test
    @DisplayName("Should avoid another provider call when a full result page already has images")
    void shouldNotEnrichACompleteResultPage() {
        final StubExtractor first = new StubExtractor(createPlant("https://example.org/plant.jpg"));
        final StubExtractor imageProvider = new StubExtractor(createPlant("https://example.org/other.jpg"));
        first.setNext(imageProvider);

        first.extractPlants("Example plant", 1);

        Assertions.assertEquals(0, imageProvider.getCalls());
    }


    @Test
    @DisplayName("Should collapse related provider taxa around an exact reviewed common name")
    void shouldCollapseRelatedProviderTaxaAroundExactReviewedName() {
        final StubExtractor reviewedCatalog = new StubExtractor(
            createPlant("Helianthus annuus", "Sunflower", "https://example.org/sunflower.jpg"));
        final StubExtractor provider = new StubExtractor(
            createPlant("Helianthus annuus", "common sunflower", null),
            createPlant("Helianthus argophyllus", "silverleaf sunflower", null),
            createPlant("Helianthus maximiliani", "Maximilian sunflower", null),
            createPlant("Helianthus tuberosus", "Jerusalem artichoke", null),
            createPlant("Helianthus petiolaris", "prairie sunflower", null));
        reviewedCatalog.setNext(provider);

        final List<BotanicalInfo> result = reviewedCatalog.extractPlants("sunflower", 5);

        Assertions.assertEquals(0, provider.getCalls());
        Assertions.assertEquals(1, result.size());
        Assertions.assertEquals("Helianthus annuus", result.get(0).getSpecies());
        Assertions.assertEquals("https://example.org/sunflower.jpg", result.get(0).getImage().getUrl());
    }


    @Test
    @DisplayName("Should rank an exact downstream result and remove unrelated typo coincidences")
    void shouldPreferAnExactDownstreamResult() {
        final StubExtractor fuzzyCatalog = new StubExtractor(
            createPlant("Example one", "pale", "https://example.org/one.jpg"),
            createPlant("Example two", "sale", "https://example.org/two.jpg"),
            createPlant("Example three", "male", "https://example.org/three.jpg"),
            createPlant("Example four", "tale", "https://example.org/four.jpg"),
            createPlant("Example five", "dale", "https://example.org/five.jpg")
        );
        final BotanicalInfo exactProviderMatch = createPlant(
            "Brassica oleracea", "cabbage, broccoli, and allies", "https://example.org/kale.jpg");
        exactProviderMatch.getSynonyms().add("kale");
        final StubExtractor externalProvider = new StubExtractor(exactProviderMatch);
        fuzzyCatalog.setNext(externalProvider);

        final List<BotanicalInfo> result = fuzzyCatalog.extractPlants("kale", 5);

        Assertions.assertEquals(1, externalProvider.getCalls());
        Assertions.assertEquals(1, result.size());
        Assertions.assertEquals("Brassica oleracea", result.get(0).getSpecies());
        Assertions.assertEquals("SCIENTIFIC_SYNONYM", result.get(0).getSearchMatchReason());
    }


    @Test
    @DisplayName("Should retain typo matches when no stronger result exists")
    void shouldRetainAUsefulTypoMatch() {
        final StubExtractor catalog = new StubExtractor(
            createPlant("Epipremnum aureum", "pothos", "https://example.org/pothos.jpg"));

        final List<BotanicalInfo> result = catalog.extractPlants("potohs", 5);

        Assertions.assertEquals(1, result.size());
        Assertions.assertEquals("Epipremnum aureum", result.get(0).getSpecies());
        Assertions.assertEquals("COMMON_NAME_TYPO", result.get(0).getSearchMatchReason());
    }


    private static BotanicalInfo createPlant(String imageUrl) {
        return createPlant("Example plant", null, imageUrl);
    }


    private static BotanicalInfo createPlant(String scientificName, String commonName, String imageUrl) {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies(scientificName);
        if (commonName != null) {
            botanicalInfo.getCommonNames().add(new BotanicalCommonName(
                commonName, "en", "US", true, BotanicalInfoCreator.TRUSTED_NAME_INDEX));
        }
        if (imageUrl != null) {
            final BotanicalInfoImage image = new BotanicalInfoImage();
            image.setId(null);
            image.setUrl(imageUrl);
            botanicalInfo.setImage(image);
        }
        return botanicalInfo;
    }


    private static final class StubExtractor extends AbstractPlantInfoExtractorStep {
        private final Set<BotanicalInfo> results;
        private int calls;


        private StubExtractor(BotanicalInfo... results) {
            this.results = new LinkedHashSet<>(List.of(results));
        }


        @Override
        protected Set<BotanicalInfo> extractPlantsInternal(String searchTerm, int size,
                                                            String locale, String region) {
            calls++;
            return results;
        }


        @Override
        protected Set<BotanicalInfo> getAllInternal(int size) {
            return results;
        }


        private int getCalls() {
            return calls;
        }
    }
}
