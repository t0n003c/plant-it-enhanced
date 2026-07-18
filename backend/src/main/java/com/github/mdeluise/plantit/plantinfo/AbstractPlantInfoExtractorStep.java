package com.github.mdeluise.plantit.plantinfo;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCatalogMerger;
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
        if (shouldQueryNext(result, size)) {
            next.extractPlants(partialPlantScientificName, size, locale, region)
                .forEach(candidate -> addOrMerge(result, candidate));
        }
        return new ArrayList<>(new ArrayList<>(result).subList(0, Math.min(size, result.size())));
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


    private boolean shouldQueryNext(Set<BotanicalInfo> result, int size) {
        return next != null && (result.size() < size || result.stream().anyMatch(
            botanicalInfo -> !BotanicalInfoCatalogMerger.hasUsableImage(botanicalInfo)));
    }
}
