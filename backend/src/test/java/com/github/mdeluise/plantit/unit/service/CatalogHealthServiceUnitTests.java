package com.github.mdeluise.plantit.unit.service;

import java.util.List;
import java.util.Map;

import com.github.mdeluise.plantit.catalog.CatalogGapService;
import com.github.mdeluise.plantit.catalog.CatalogHealthService;
import com.github.mdeluise.plantit.catalog.CatalogHealthSnapshot;
import com.github.mdeluise.plantit.catalog.CatalogQualityManifest;
import com.github.mdeluise.plantit.plantinfo.care.CuratedCareProvider;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.core.io.ClassPathResource;

@DisplayName("Unit tests for catalog health coverage")
class CatalogHealthServiceUnitTests {

    @Test
    @DisplayName("Should enforce complete cultivated care without requiring it for trail plants")
    void shouldReportCompleteTierCoverage() {
        final CatalogGapService gapService = Mockito.mock(CatalogGapService.class);
        Mockito.when(gapService.activeGaps()).thenReturn(List.of());
        Mockito.when(gapService.activeGapCounts()).thenReturn(Map.of());
        final CatalogHealthService service = new CatalogHealthService(
            new CatalogQualityManifest(new ClassPathResource("catalog-quality-manifest.json")),
            new TrustedCommonNameIndex(new ClassPathResource("trusted-common-names.json")),
            new CuratedCareProvider(new ClassPathResource("plant-care-catalog.json")),
            gapService
        );

        final CatalogHealthSnapshot result = service.get();

        Assertions.assertTrue(result.healthy());
        Assertions.assertEquals(179, result.totals().reviewedEntries());
        Assertions.assertEquals(869, result.totals().reviewedQueries());
        Assertions.assertEquals(88, result.totals().curatedCareProfiles());
        Assertions.assertEquals(19, result.totals().liveCanaries());
        Assertions.assertTrue(result.policyIssues().isEmpty());
        final CatalogHealthSnapshot.TierCoverage cultivated = result.tiers().stream()
            .filter(tier -> "CURATED_CULTIVATED".equals(tier.name()))
            .findFirst()
            .orElseThrow();
        final CatalogHealthSnapshot.TierCoverage trail = result.tiers().stream()
            .filter(tier -> "NORTH_AMERICAN_TRAIL".equals(tier.name()))
            .findFirst()
            .orElseThrow();
        Assertions.assertEquals(89, cultivated.entries());
        Assertions.assertEquals(89, cultivated.careCompleteEntries());
        Assertions.assertEquals(100, cultivated.careCoveragePercent());
        Assertions.assertEquals(90, trail.entries());
        Assertions.assertEquals(0, trail.careRequiredEntries());
        Assertions.assertEquals(100, trail.careCoveragePercent());
    }
}
