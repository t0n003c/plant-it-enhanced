package com.github.mdeluise.plantit.catalog;

import java.time.Instant;

public record CatalogGapSummary(CatalogGapType type, String subject, String scientificName,
                                int occurrences, Instant firstSeenAt, Instant lastSeenAt) {
}
