package com.github.mdeluise.plantit.plant.care;

import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Care schedule suggestion")
public record CareScheduleSuggestion(
    @Schema(description = "Suggested days between soil checks and likely watering") int intervalDays,
    @Schema(description = "Confidence from zero to one") double confidence,
    @Schema(description = "Profile factors used for the suggestion") List<String> factors
) {
}
