package com.github.mdeluise.plantit.plantinfo.search;

import java.util.LinkedHashSet;
import java.util.Set;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;
import com.github.mdeluise.plantit.plantinfo.AbstractPlantInfoExtractorStep;
import com.github.mdeluise.plantit.plantinfo.gbif.GbifTaxonomyVerifier;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;

@Service
@Order(2)
public class TrustedCommonNamePlantInfoExtractorStep extends AbstractPlantInfoExtractorStep {
    private final TrustedCommonNameIndex trustedCommonNameIndex;
    private final GbifTaxonomyVerifier gbifTaxonomyVerifier;


    public TrustedCommonNamePlantInfoExtractorStep(TrustedCommonNameIndex trustedCommonNameIndex,
                                                   GbifTaxonomyVerifier gbifTaxonomyVerifier) {
        this.trustedCommonNameIndex = trustedCommonNameIndex;
        this.gbifTaxonomyVerifier = gbifTaxonomyVerifier;
    }


    @Override
    protected Set<BotanicalInfo> extractPlantsInternal(String searchTerm, int size,
                                                        String locale, String region) {
        if (searchTerm.isBlank() || "*".equals(searchTerm)) {
            return new LinkedHashSet<>();
        }
        final Set<BotanicalInfo> result = new LinkedHashSet<>();
        trustedCommonNameIndex.search(searchTerm, size).stream()
                              .map(gbifTaxonomyVerifier::verify)
                              .forEach(result::add);
        return result;
    }


    @Override
    protected Set<BotanicalInfo> getAllInternal(int size) {
        return new LinkedHashSet<>();
    }
}
