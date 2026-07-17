package com.github.mdeluise.plantit.plantinfo.care;

import java.util.Optional;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class PlantCareEnrichmentService {
    private final BotanicalInfoService botanicalInfoService;
    private final TrefleCareProvider careProvider;


    @Autowired
    public PlantCareEnrichmentService(BotanicalInfoService botanicalInfoService, TrefleCareProvider careProvider) {
        this.botanicalInfoService = botanicalInfoService;
        this.careProvider = careProvider;
    }


    public BotanicalInfo refresh(long botanicalInfoId) {
        final BotanicalInfo botanicalInfo = botanicalInfoService.get(botanicalInfoId);
        final Optional<PlantCareInfo> refreshed = careProvider.fetch(botanicalInfo.getSpecies());
        return refreshed.map(careInfo -> botanicalInfoService.updateCareInfo(botanicalInfoId, careInfo))
                        .orElse(botanicalInfo);
    }
}
