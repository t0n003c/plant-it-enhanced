package com.github.mdeluise.plantit.botanicalinfo.safety;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Reviewed toxicity status for one person or animal audience")
public enum PlantSafetyStatus {
    NON_TOXIC,
    CAUTION,
    TOXIC,
    HIGHLY_TOXIC,
    UNKNOWN
}
