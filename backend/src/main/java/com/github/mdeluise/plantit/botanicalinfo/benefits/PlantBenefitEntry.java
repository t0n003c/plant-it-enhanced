package com.github.mdeluise.plantit.botanicalinfo.benefits;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "A reviewed food, enrichment, or traditional-use note for a specified audience")
public record PlantBenefitEntry(
    @Schema(description = "Audience for this note: HUMAN or PET") String audience,
    @Schema(description = "Type of note: FOOD, ENRICHMENT, or MEDICINE") String category,
    @Schema(description = "Short title") String title,
    @Schema(description = "Plain-language description") String summary,
    @Schema(description = "Important limitation or caution") String caution
) {
}
