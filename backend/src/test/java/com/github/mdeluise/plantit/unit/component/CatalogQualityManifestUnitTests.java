package com.github.mdeluise.plantit.unit.component;

import java.util.Set;

import com.github.mdeluise.plantit.catalog.CatalogQualityManifest;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for the unified catalog quality manifest")
class CatalogQualityManifestUnitTests {

    @Test
    @DisplayName("Should assign every reviewed plant to exactly one support tier")
    void shouldAssignEveryCatalogEntryToOneTier() {
        final CatalogQualityManifest manifest = createManifest();
        final TrustedCommonNameIndex index = new TrustedCommonNameIndex(
            new ClassPathResource("trusted-common-names.json"));

        Assertions.assertEquals(1, manifest.getSchemaVersion());
        Assertions.assertEquals(2, manifest.getTiers().size());
        Assertions.assertEquals(11, manifest.getLiveCanaries().size());
        index.catalogEntries().forEach(entry -> Assertions.assertNotNull(
            manifest.policyFor(entry.catalogTags())));
    }


    @Test
    @DisplayName("Should keep cultivated and trail requirements separate")
    void shouldKeepSupportRequirementsSeparate() {
        final CatalogQualityManifest manifest = createManifest();

        final var cultivated = manifest.policyFor(Set.of());
        final var trail = manifest.policyFor(Set.of(TrustedCommonNameIndex.NORTH_AMERICAN_TRAIL_TAG));

        Assertions.assertEquals("CURATED_CULTIVATED", cultivated.name());
        Assertions.assertEquals(Set.of("light", "soilHumidity"), Set.copyOf(cultivated.requiredCareFields()));
        Assertions.assertTrue(cultivated.requiresImage());
        Assertions.assertEquals("NORTH_AMERICAN_TRAIL", trail.name());
        Assertions.assertTrue(trail.requiredCareFields().isEmpty());
        Assertions.assertTrue(trail.requiresImage());
    }


    @Test
    @DisplayName("Should resolve every live canary everyday query to its accepted taxon")
    void shouldResolveEveryLiveCanaryQuery() {
        final CatalogQualityManifest manifest = createManifest();
        final TrustedCommonNameIndex index = new TrustedCommonNameIndex(
            new ClassPathResource("trusted-common-names.json"));

        manifest.getLiveCanaries().forEach(canary -> {
            final var results = index.search(canary.query(), 1);
            Assertions.assertFalse(results.isEmpty(), "No reviewed result for " + canary.query());
            Assertions.assertTrue(
                canary.acceptedScientificNames().contains(results.get(0).getSpecies()),
                "Unexpected reviewed taxon for " + canary.query()
            );
        });
    }


    private CatalogQualityManifest createManifest() {
        return new CatalogQualityManifest(new ClassPathResource("catalog-quality-manifest.json"));
    }
}
