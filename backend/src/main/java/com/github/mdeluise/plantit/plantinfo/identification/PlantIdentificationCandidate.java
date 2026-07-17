package com.github.mdeluise.plantit.plantinfo.identification;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;

public record PlantIdentificationCandidate(BotanicalInfo botanicalInfo, double confidence, String modelVersion) {
}
