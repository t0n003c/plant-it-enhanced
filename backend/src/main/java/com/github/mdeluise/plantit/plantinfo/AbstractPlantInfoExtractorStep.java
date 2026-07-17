package com.github.mdeluise.plantit.plantinfo;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.plantinfo.search.PlantNameNormalizer;
import org.springframework.stereotype.Component;

@Component
public abstract class AbstractPlantInfoExtractorStep implements PlantInfoExtractorStep {
    private PlantInfoExtractorStep next;

    @Override
    public void setNext(PlantInfoExtractorStep next) {
        this.next = next;
    }


    public List<BotanicalInfo> extractPlants(String partialPlantScientificName, int size) {
        final Set<BotanicalInfo> result =
            new LinkedHashSet<>(extractPlantsInternal(partialPlantScientificName, size));
        if (result.size() < size && next != null) {
            next.extractPlants(partialPlantScientificName, size).forEach(candidate -> {
                if (!containsSpecies(result, candidate)) {
                    result.add(candidate);
                }
            });
        }
        return new ArrayList<>(new ArrayList<>(result).subList(0, Math.min(size, result.size())));
    }


    protected abstract Set<BotanicalInfo> extractPlantsInternal(String partialPlantScientificName, int size);


    public List<BotanicalInfo> getAll(int size) {
        final ArrayList<BotanicalInfo> result = new ArrayList<>(getAllInternal(size));
        if (result.size() < size && next != null) {
            result.addAll(next.getAll(size));
        }
        return new ArrayList<>(new ArrayList<>(result).subList(0, Math.min(size, result.size())));
    }


    protected abstract Set<BotanicalInfo> getAllInternal(int size);


    private boolean containsSpecies(Set<BotanicalInfo> botanicalInfos, BotanicalInfo candidate) {
        final String candidateSpecies = PlantNameNormalizer.normalize(candidate.getSpecies());
        return botanicalInfos.stream()
                             .map(BotanicalInfo::getSpecies)
                             .map(PlantNameNormalizer::normalize)
                             .anyMatch(candidateSpecies::equals);
    }
}
