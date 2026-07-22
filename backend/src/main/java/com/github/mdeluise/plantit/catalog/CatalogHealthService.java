package com.github.mdeluise.plantit.catalog;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.github.mdeluise.plantit.catalog.CatalogHealthSnapshot.CatalogTotals;
import com.github.mdeluise.plantit.catalog.CatalogHealthSnapshot.TierCoverage;
import com.github.mdeluise.plantit.catalog.CatalogQualityManifest.TierPolicy;
import com.github.mdeluise.plantit.plantinfo.care.CuratedCareProvider;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex;
import com.github.mdeluise.plantit.plantinfo.search.TrustedCommonNameIndex.CatalogEntry;
import org.springframework.stereotype.Service;

@Service
public class CatalogHealthService {
    private final CatalogQualityManifest manifest;
    private final TrustedCommonNameIndex trustedNameIndex;
    private final CuratedCareProvider curatedCareProvider;
    private final CatalogGapService catalogGapService;


    public CatalogHealthService(CatalogQualityManifest manifest,
                                TrustedCommonNameIndex trustedNameIndex,
                                CuratedCareProvider curatedCareProvider,
                                CatalogGapService catalogGapService) {
        this.manifest = manifest;
        this.trustedNameIndex = trustedNameIndex;
        this.curatedCareProvider = curatedCareProvider;
        this.catalogGapService = catalogGapService;
    }


    public CatalogHealthSnapshot get() {
        final List<CatalogEntry> entries = trustedNameIndex.catalogEntries();
        final List<CatalogEntry> reviewedEntries = entries.stream()
                                                         .filter(entry -> !entry.catalogTags().contains(
                                                             TrustedCommonNameIndex.SEARCH_DISCOVERY_TAG))
                                                         .toList();
        final Map<String, List<CatalogEntry>> entriesByTier = new LinkedHashMap<>();
        manifest.getTiers().forEach(policy -> entriesByTier.put(policy.name(), new ArrayList<>()));
        entries.forEach(entry -> entriesByTier.get(manifest.policyFor(entry.catalogTags()).name()).add(entry));

        final List<String> policyIssues = new ArrayList<>();
        final List<TierCoverage> tierCoverage = manifest.getTiers().stream()
                                                        .map(policy -> coverage(
                                                            policy,
                                                            entriesByTier.get(policy.name()),
                                                            policyIssues
                                                        ))
                                                        .toList();
        final List<CatalogGapSummary> recentGaps = catalogGapService.activeGaps();
        final long activeGapCount = catalogGapService.activeGapCount();
        final Map<CatalogGapType, Long> gapCounts = catalogGapService.activeGapCounts();
        final CatalogTotals totals = new CatalogTotals(
            reviewedEntries.size(),
            queryCount(reviewedEntries),
            entries.size(),
            queryCount(entries),
            curatedCareProvider.profileCount(),
            manifest.getLiveCanaries().size(),
            (int) entries.stream().filter(entry -> entry.catalogTags().contains(
                TrustedCommonNameIndex.CONTACT_HAZARD_TAG)).count()
        );
        return new CatalogHealthSnapshot(
            manifest.getSchemaVersion(),
            Instant.now(),
            policyIssues.isEmpty() && activeGapCount == 0,
            totals,
            tierCoverage,
            activeGapCount,
            Map.copyOf(gapCounts),
            recentGaps,
            List.copyOf(policyIssues)
        );
    }


    private int queryCount(List<CatalogEntry> entries) {
        return entries.stream()
                      .mapToInt(entry -> 1 + entry.scientificSynonyms().size() + entry.commonNames().size())
                      .sum();
    }


    private TierCoverage coverage(TierPolicy policy, List<CatalogEntry> entries,
                                  List<String> policyIssues) {
        int careRequired = 0;
        int careComplete = 0;
        int reviewedQueries = 0;
        for (CatalogEntry entry : entries) {
            reviewedQueries += 1 + entry.scientificSynonyms().size() + entry.commonNames().size();
            if (!policy.requiredCareFields().isEmpty()) {
                careRequired++;
                final Set<String> available = curatedCareProvider.availableFields(entry.scientificName());
                if (available.containsAll(policy.requiredCareFields())) {
                    careComplete++;
                } else {
                    final List<String> missing = policy.requiredCareFields().stream()
                                                       .filter(field -> !available.contains(field))
                                                       .toList();
                    policyIssues.add(entry.scientificName() + " is missing care fields: " +
                                         String.join(", ", missing));
                }
            }
        }
        final int imageRequired = policy.requiresImage() ? entries.size() : 0;
        return new TierCoverage(
            policy.name(),
            entries.size(),
            reviewedQueries,
            imageRequired,
            careRequired,
            careComplete,
            percentage(entries.size(), entries.size()),
            percentage(careComplete, careRequired)
        );
    }


    private int percentage(int complete, int total) {
        return total == 0 ? 100 : (int) Math.round(complete * 100.0 / total);
    }
}
