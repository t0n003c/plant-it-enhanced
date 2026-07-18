package com.github.mdeluise.plantit.unit.component;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
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

        first.extractPlants("plant", 1);

        Assertions.assertEquals(0, imageProvider.getCalls());
    }


    private static BotanicalInfo createPlant(String imageUrl) {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.setSpecies("Example plant");
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
