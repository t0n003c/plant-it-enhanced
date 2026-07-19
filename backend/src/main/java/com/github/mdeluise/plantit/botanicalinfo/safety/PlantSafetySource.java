package com.github.mdeluise.plantit.botanicalinfo.safety;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Attributable source for reviewed plant-safety guidance")
public record PlantSafetySource(
    @Schema(description = "Source organization") String name,
    @Schema(description = "Direct source page") String url
) {
}
