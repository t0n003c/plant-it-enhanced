package com.github.mdeluise.plantit.catalog;

import java.time.Instant;
import java.util.List;
import java.util.Map;

public record CatalogHealthSnapshot(int schemaVersion, Instant checkedAt, boolean healthy,
                                    CatalogTotals totals, List<TierCoverage> tiers,
                                    long activeGapCount, Map<CatalogGapType, Long> activeGapCounts,
                                    List<CatalogGapSummary> recentGaps, List<String> policyIssues) {

    public record CatalogTotals(int reviewedEntries, int reviewedQueries, int curatedCareProfiles,
                                int liveCanaries, int contactHazards) {
    }


    public record TierCoverage(String name, int entries, int reviewedQueries,
                               int imageRequiredEntries, int careRequiredEntries,
                               int careCompleteEntries, int searchCoveragePercent,
                               int careCoveragePercent) {
    }
}
