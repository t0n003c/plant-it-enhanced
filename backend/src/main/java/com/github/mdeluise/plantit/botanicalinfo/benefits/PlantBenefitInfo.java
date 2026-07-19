package com.github.mdeluise.plantit.botanicalinfo.benefits;

import java.time.Instant;
import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Reviewed food, enrichment, and traditional-use notes for a botanical result")
public record PlantBenefitInfo(
    List<PlantBenefitEntry> entries,
    List<PlantBenefitSource> sources,
    Instant lastVerifiedAt,
    boolean reviewed,
    String matchedTaxon
) {
    public static PlantBenefitInfo unknown() {
        return new PlantBenefitInfo(List.of(), List.of(), null, false, null);
    }
}
