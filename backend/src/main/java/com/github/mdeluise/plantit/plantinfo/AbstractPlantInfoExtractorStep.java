package com.github.mdeluise.plantit.plantinfo;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCatalogMerger;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchMatchReason;
import com.github.mdeluise.plantit.plantinfo.search.PlantSearchScorer;
import org.springframework.stereotype.Component;

@Component
public abstract class AbstractPlantInfoExtractorStep implements PlantInfoExtractorStep {
    private PlantInfoExtractorStep next;

    @Override
    public void setNext(PlantInfoExtractorStep next) {
        this.next = next;
    }


    public List<BotanicalInfo> extractPlants(String partialPlantScientificName, int size) {
        return extractPlants(partialPlantScientificName, size, null, null);
    }


    @Override
    public List<BotanicalInfo> extractPlants(String partialPlantScientificName, int size, String locale, String region) {
        final Set<BotanicalInfo> result = new LinkedHashSet<>();
        extractPlantsInternal(partialPlantScientificName, size, locale, region)
            .forEach(candidate -> addOrMerge(result, candidate));
        if (shouldQueryNext(result, size, partialPlantScientificName)) {
            next.extractPlants(partialPlantScientificName, size, locale, region)
                .forEach(candidate -> addOrMerge(result, candidate));
        }
        final List<BotanicalInfo> strongMatches = result.stream()
                                                         .filter(candidate -> PlantSearchScorer.isStrongMatch(
                                                             partialPlantScientificName, candidate))
                                                         .toList();
        if (!strongMatches.isEmpty()) {
            result.removeIf(candidate -> strongMatches.stream().noneMatch(strongMatch ->
                BotanicalInfoCatalogMerger.describesSameTaxon(strongMatch, candidate)));
        }
        final boolean hasStrongMatch = !strongMatches.isEmpty();
        return result.stream()
                     .filter(candidate -> !hasStrongMatch || PlantSearchScorer.evaluate(
                         partialPlantScientificName, candidate).reason() != PlantSearchMatchReason.COMMON_NAME_TYPO)
                     .sorted(searchResultComparator(partialPlantScientificName))
                     .limit(size)
                     .peek(candidate -> PlantSearchScorer.applyMatchMetadata(
                         partialPlantScientificName, candidate))
                     .toList();
    }


    protected abstract Set<BotanicalInfo> extractPlantsInternal(String partialPlantScientificName, int size,
                                                                 String locale, String region);


    public List<BotanicalInfo> getAll(int size) {
        final ArrayList<BotanicalInfo> result = new ArrayList<>(getAllInternal(size));
        if (result.size() < size && next != null) {
            result.addAll(next.getAll(size));
        }
        return new ArrayList<>(new ArrayList<>(result).subList(0, Math.min(size, result.size())));
    }


    protected abstract Set<BotanicalInfo> getAllInternal(int size);


    private void addOrMerge(Set<BotanicalInfo> botanicalInfos, BotanicalInfo candidate) {
        final BotanicalInfo existing = botanicalInfos.stream()
                                                       .filter(saved -> BotanicalInfoCatalogMerger.describesSameTaxon(
                                                           saved, candidate))
                                                       .findFirst()
                                                       .orElse(null);
        if (existing == null) {
            botanicalInfos.add(candidate);
            return;
        }
        BotanicalInfoCatalogMerger.mergeInto(existing, candidate);
    }


    private boolean shouldQueryNext(Set<BotanicalInfo> result, int size, String searchTerm) {
        if (result.stream().anyMatch(botanicalInfo ->
            PlantSearchScorer.isStrongMatch(searchTerm, botanicalInfo) &&
                BotanicalInfoCatalogMerger.hasUsableImage(botanicalInfo))) {
            return false;
        }
        return next != null && (result.size() < size || result.stream().anyMatch(
            botanicalInfo -> !BotanicalInfoCatalogMerger.hasUsableImage(botanicalInfo)) ||
                   result.stream().noneMatch(botanicalInfo -> PlantSearchScorer.isStrongMatch(
                       searchTerm, botanicalInfo)));
    }


    private Comparator<BotanicalInfo> searchResultComparator(String searchTerm) {
        return PlantSearchScorer.relevanceComparator(searchTerm).thenComparing(
            Comparator.comparing(BotanicalInfoCatalogMerger::hasUsableImage).reversed()
        );
    }
}
