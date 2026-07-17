package com.github.mdeluise.plantit.plantinfo.inaturalist;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.AbstractPlantInfoExtractorStep;
import com.github.mdeluise.plantit.plantinfo.config.INaturalistProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;

@Service
@Order(2)
public class INaturalistPlantInfoExtractorStep extends AbstractPlantInfoExtractorStep {
    private final INaturalistRequestMaker requestMaker;
    private final BotanicalInfoService botanicalInfoService;
    private final boolean enabled;
    private final Logger logger = LoggerFactory.getLogger(INaturalistPlantInfoExtractorStep.class);


    public INaturalistPlantInfoExtractorStep(INaturalistRequestMaker requestMaker,
                                             BotanicalInfoService botanicalInfoService,
                                             INaturalistProperties naturalistProperties) {
        this.requestMaker = requestMaker;
        this.botanicalInfoService = botanicalInfoService;
        this.enabled = naturalistProperties.isEnabled();
    }


    @Override
    protected Set<BotanicalInfo> extractPlantsInternal(String searchTerm, int size) {
        if (!enabled || searchTerm.isBlank() || "*".equals(searchTerm)) {
            return new LinkedHashSet<>();
        }
        try {
            final List<BotanicalInfo> result = requestMaker.search(searchTerm, size).stream()
                                                            .filter(info -> !existsLocally(info))
                                                            .toList();
            return new LinkedHashSet<>(result);
        } catch (InfoExtractionException e) {
            logger.warn("iNaturalist search unavailable; continuing with the next provider: {}", e.getMessage());
            return new LinkedHashSet<>();
        }
    }


    @Override
    protected Set<BotanicalInfo> getAllInternal(int size) {
        return new LinkedHashSet<>();
    }


    private boolean existsLocally(BotanicalInfo botanicalInfo) {
        return botanicalInfoService.existsExternalId(BotanicalInfoCreator.INATURALIST,
                                                      botanicalInfo.getExternalId()) ||
                   botanicalInfoService.existsSpecies(botanicalInfo.getSpecies());
    }
}
