package com.github.mdeluise.plantit.plantinfo.care;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.exception.CareProviderNotConfiguredException;
import com.github.mdeluise.plantit.exception.CareProviderUnavailableException;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class PlantCareEnrichmentService {
    private final BotanicalInfoService botanicalInfoService;
    private final TrefleCareProvider trefleCareProvider;
    private final PerenualCareProvider perenualCareProvider;


    @Autowired
    public PlantCareEnrichmentService(BotanicalInfoService botanicalInfoService,
                                      TrefleCareProvider trefleCareProvider,
                                      PerenualCareProvider perenualCareProvider) {
        this.botanicalInfoService = botanicalInfoService;
        this.trefleCareProvider = trefleCareProvider;
        this.perenualCareProvider = perenualCareProvider;
    }


    public BotanicalInfo refresh(long botanicalInfoId) {
        final BotanicalInfo botanicalInfo = botanicalInfoService.get(botanicalInfoId);
        final Optional<PlantCareInfo> refreshed = findCare(botanicalInfo.getSpecies());
        return refreshed.map(careInfo -> botanicalInfoService.updateCareInfo(botanicalInfoId, careInfo))
                        .orElse(botanicalInfo);
    }


    @Cacheable(cacheNames = "plant-care-preview", key = "#scientificName.toLowerCase()",
               unless = "#result.isAllNull()")
    public PlantCareInfo preview(String scientificName) {
        return findCare(scientificName).orElseGet(PlantCareInfo::new);
    }


    private Optional<PlantCareInfo> findCare(String scientificName) {
        if (!trefleCareProvider.isConfigured() && !perenualCareProvider.isConfigured()) {
            throw new CareProviderNotConfiguredException();
        }
        final List<InfoExtractionException> failures = new ArrayList<>();
        Optional<PlantCareInfo> refreshed = fetchFromTrefle(scientificName, failures);
        if (refreshed.isEmpty()) {
            refreshed = fetchFromPerenual(scientificName, failures);
        }
        if (refreshed.isEmpty() && !failures.isEmpty()) {
            throw new CareProviderUnavailableException();
        }
        return refreshed;
    }


    private Optional<PlantCareInfo> fetchFromTrefle(String scientificName,
                                                    List<InfoExtractionException> failures) {
        Optional<PlantCareInfo> result = Optional.empty();
        if (trefleCareProvider.isConfigured()) {
            try {
                result = trefleCareProvider.fetch(scientificName);
            } catch (InfoExtractionException exception) {
                failures.add(exception);
            }
        }
        return result;
    }


    private Optional<PlantCareInfo> fetchFromPerenual(String scientificName,
                                                      List<InfoExtractionException> failures) {
        Optional<PlantCareInfo> result = Optional.empty();
        if (perenualCareProvider.isConfigured()) {
            try {
                result = perenualCareProvider.fetch(scientificName);
            } catch (InfoExtractionException exception) {
                failures.add(exception);
            }
        }
        return result;
    }
}
