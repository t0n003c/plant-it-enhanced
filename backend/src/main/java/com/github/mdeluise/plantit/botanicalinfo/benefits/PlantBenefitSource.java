package com.github.mdeluise.plantit.botanicalinfo.benefits;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Source supporting a plant benefit or use note")
public record PlantBenefitSource(
    String name,
    String url
) {
}
