package com.github.mdeluise.plantit.unit.component;

import java.time.Instant;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalCommonName;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCatalogMerger;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.image.BotanicalInfoImage;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for canonical plant catalog merging")
class BotanicalInfoCatalogMergerUnitTests {

    @Test
    @DisplayName("Should derive the canonical taxon key from the GBIF reference")
    void shouldDeriveCanonicalTaxonKey() {
        final BotanicalInfo botanicalInfo = new BotanicalInfo();
        botanicalInfo.getExternalReferences().put("GBIF", "11041822");

        BotanicalInfoCatalogMerger.prepareCanonicalIdentity(botanicalInfo);

        Assertions.assertEquals("11041822", botanicalInfo.getCanonicalTaxonKey());
    }


    @Test
    @DisplayName("Should trust distinct canonical keys over matching text")
    void shouldNotMergeDistinctCanonicalTaxa() {
        final BotanicalInfo left = createTaxon("1", "Example plant");
        final BotanicalInfo right = createTaxon("2", "Example plant");

        Assertions.assertFalse(BotanicalInfoCatalogMerger.describesSameTaxon(left, right));
    }


    @Test
    @DisplayName("Should keep distinct reviewed everyday-name variants separate")
    void shouldNotMergeDistinctCatalogVariants() {
        final BotanicalInfo bellPepper = createTaxon("", "Capsicum annuum");
        bellPepper.setCatalogVariant("Bell pepper");
        final BotanicalInfo thaiChili = createTaxon("", "Capsicum annuum");
        thaiChili.setCatalogVariant("Thai chili");

        Assertions.assertFalse(BotanicalInfoCatalogMerger.describesSameTaxon(bellPepper, thaiChili));
    }


    @Test
    @DisplayName("Should merge provider aliases while preserving existing care values")
    void shouldMergeProviderRecordsSafely() {
        final BotanicalInfo target = createTaxon("11041822", "Sansevieria trifasciata");
        target.setCreator(BotanicalInfoCreator.FLORA_CODEX);
        target.setLastVerifiedAt(Instant.parse("2025-01-01T00:00:00Z"));
        target.getExternalReferences().put("FLORA_CODEX", "flora-1");
        target.getPlantCareInfo().setLight(3);
        target.getCommonNames().add(new BotanicalCommonName(
            "Snake Plant", "en", "US", true, BotanicalInfoCreator.FLORA_CODEX
        ));

        final BotanicalInfo source = createTaxon("11041822", "Dracaena trifasciata");
        source.setCreator(BotanicalInfoCreator.INATURALIST);
        source.setFamily("Asparagaceae");
        source.setGenus("Dracaena");
        source.setLastVerifiedAt(Instant.parse("2026-01-01T00:00:00Z"));
        source.getExternalReferences().put("INATURALIST", "inat-1");
        source.getCatalogTags().add(TrustedCommonNameIndex.NORTH_AMERICAN_TRAIL_TAG);
        source.getPlantCareInfo().setLight(5);
        source.getPlantCareInfo().setHumidity(60);
        source.getSynonyms().add("Mother-in-Law's Tongue");
        source.getCommonNames().add(new BotanicalCommonName(
            "Mother-in-Law's Tongue", "EN", "us", true, BotanicalInfoCreator.INATURALIST
        ));

        final BotanicalInfo merged = BotanicalInfoCatalogMerger.mergeInto(target, source);

        Assertions.assertEquals("Dracaena trifasciata", merged.getSpecies());
        Assertions.assertEquals("Dracaena", merged.getGenus());
        Assertions.assertEquals("Asparagaceae", merged.getFamily());
        Assertions.assertTrue(merged.getSynonyms().contains("Sansevieria trifasciata"));
        Assertions.assertTrue(merged.getSynonyms().contains("Mother-in-Law's Tongue"));
        Assertions.assertEquals("flora-1", merged.getExternalReferences().get("FLORA_CODEX"));
        Assertions.assertEquals("inat-1", merged.getExternalReferences().get("INATURALIST"));
        Assertions.assertTrue(merged.getCatalogTags().contains(
            TrustedCommonNameIndex.NORTH_AMERICAN_TRAIL_TAG));
        Assertions.assertEquals(3, merged.getPlantCareInfo().getLight());
        Assertions.assertEquals(60, merged.getPlantCareInfo().getHumidity());
        Assertions.assertEquals(2, merged.getCommonNames().size());
        Assertions.assertEquals(1, merged.getCommonNames().stream()
                                                 .filter(BotanicalCommonName::isPreferred)
                                                 .count());
        Assertions.assertEquals(Instant.parse("2026-01-01T00:00:00Z"), merged.getLastVerifiedAt());
    }


    @Test
    @DisplayName("Should fill a missing catalog image from a provider")
    void shouldFillMissingCatalogImage() {
        final BotanicalInfo target = createTaxon("1", "Monstera deliciosa");
        final BotanicalInfo source = createTaxon("1", "Monstera deliciosa");
        source.setImage(createImage("https://example.org/monstera-medium.jpg", "INATURALIST"));

        final BotanicalInfo merged = BotanicalInfoCatalogMerger.mergeInto(target, source);

        Assertions.assertSame(source.getImage(), merged.getImage());
        Assertions.assertEquals("INATURALIST", merged.getImage().getSource());
    }


    @Test
    @DisplayName("Should preserve an existing image instead of replacing it with a provider image")
    void shouldPreserveExistingCatalogImage() {
        final BotanicalInfo target = createTaxon("1", "Monstera deliciosa");
        target.setImage(createImage("https://example.org/user-photo.jpg", null));
        final BotanicalInfo source = createTaxon("1", "Monstera deliciosa");
        source.setImage(createImage("https://example.org/provider-photo.jpg", "INATURALIST"));

        final BotanicalInfo merged = BotanicalInfoCatalogMerger.mergeInto(target, source);

        Assertions.assertEquals("https://example.org/user-photo.jpg", merged.getImage().getUrl());
        Assertions.assertNull(merged.getImage().getSource());
    }


    private BotanicalInfo createTaxon(String canonicalKey, String species) {
        final BotanicalInfo result = new BotanicalInfo();
        result.setCanonicalTaxonKey(canonicalKey);
        result.setSpecies(species);
        result.getExternalReferences().put("GBIF", canonicalKey);
        return result;
    }


    private BotanicalInfoImage createImage(String url, String source) {
        final BotanicalInfoImage image = new BotanicalInfoImage();
        image.setId(null);
        image.setUrl(url);
        image.setSource(source);
        return image;
    }
}
