package com.github.mdeluise.plantit.unit.controller;

import java.time.Instant;
import java.util.List;
import java.util.Map;

import com.github.mdeluise.plantit.catalog.CatalogHealthController;
import com.github.mdeluise.plantit.catalog.CatalogHealthService;
import com.github.mdeluise.plantit.catalog.CatalogHealthSnapshot;
import com.github.mdeluise.plantit.catalog.CatalogHealthSnapshot.CatalogTotals;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@DisplayName("Unit tests for the catalog health endpoint")
class CatalogHealthControllerUnitTests {

    @Test
    @DisplayName("Should return a non-cacheable authenticated catalog report")
    void shouldReturnCatalogHealth() {
        final CatalogHealthService service = Mockito.mock(CatalogHealthService.class);
        final CatalogHealthSnapshot snapshot = new CatalogHealthSnapshot(
            1,
            Instant.parse("2026-07-18T00:00:00Z"),
            true,
            new CatalogTotals(179, 869, 88, 19, 11),
            List.of(),
            0,
            Map.of(),
            List.of(),
            List.of()
        );
        Mockito.when(service.get()).thenReturn(snapshot);

        final var response = new CatalogHealthController(service).get();

        Assertions.assertSame(snapshot, response.getBody());
        Assertions.assertEquals("no-store", response.getHeaders().getCacheControl());
    }
}
