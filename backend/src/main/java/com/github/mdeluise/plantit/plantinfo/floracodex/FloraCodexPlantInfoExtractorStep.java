package com.github.mdeluise.plantit.plantinfo.floracodex;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoCreator;
import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfoService;
import com.github.mdeluise.plantit.exception.InfoExtractionException;
import com.github.mdeluise.plantit.plantinfo.AbstractPlantInfoExtractorStep;
import com.github.mdeluise.plantit.plantinfo.gbif.GbifTaxonomyVerifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@Order(3)
public class FloraCodexPlantInfoExtractorStep extends AbstractPlantInfoExtractorStep {
    private final FloraCodexRequestMaker floraCodexRequestMaker;
    private final BotanicalInfoService botanicalInfoService;
    private final GbifTaxonomyVerifier gbifTaxonomyVerifier;
    private final Logger logger = LoggerFactory.getLogger(FloraCodexPlantInfoExtractorStep.class);


    public FloraCodexPlantInfoExtractorStep(FloraCodexRequestMaker floraCodexRequestMaker,
                                            BotanicalInfoService botanicalInfoService,
                                            GbifTaxonomyVerifier gbifTaxonomyVerifier) {
        super();
        this.floraCodexRequestMaker = floraCodexRequestMaker;
        this.botanicalInfoService = botanicalInfoService;
        this.gbifTaxonomyVerifier = gbifTaxonomyVerifier;
    }


    @Override
    protected Set<BotanicalInfo> extractPlantsInternal(String partialPlantScientificName, int size,
                                                        String locale, String region) {
        try {
            final Page<BotanicalInfo> result =
                floraCodexRequestMaker.fetchInfoFromPartial(partialPlantScientificName, Pageable.ofSize(size));
            final List<BotanicalInfo> filteredResult = result.stream()
                                                             .map(gbifTaxonomyVerifier::verify)
                                                             .filter(botanicalInfo -> !existAlreadyALocalVersion(
                                                                 botanicalInfo))
                                                             .toList();
            return new LinkedHashSet<>(filteredResult);
        } catch (InfoExtractionException e) {
            logger.warn("FloraCodex search unavailable: {}", e.getMessage());
            return new LinkedHashSet<>();
        }
    }


    @Override
    protected Set<BotanicalInfo> getAllInternal(int size) {
        try {
            final Page<BotanicalInfo> result = floraCodexRequestMaker.fetchAll(Pageable.ofSize(size));
            final List<BotanicalInfo> filteredResult = result.stream()
                                                             .map(gbifTaxonomyVerifier::verify)
                                                             .filter(botanicalInfo -> !existAlreadyALocalVersion(
                                                                 botanicalInfo))
                                                             .toList();
            return new LinkedHashSet<>(filteredResult);
        } catch (InfoExtractionException e) {
            logger.warn("FloraCodex catalog unavailable: {}", e.getMessage());
            return new LinkedHashSet<>();
        }
    }


    private boolean existAlreadyALocalVersion(BotanicalInfo botanicalInfo) {
        return botanicalInfoService.existsCanonicalTaxon(botanicalInfo.getCanonicalTaxonKey()) ||
                   botanicalInfoService.existsExternalId(BotanicalInfoCreator.FLORA_CODEX,
                                                           botanicalInfo.getExternalId()) ||
                   botanicalInfoService.existsSpecies(botanicalInfo.getSpecies());
    }
}
