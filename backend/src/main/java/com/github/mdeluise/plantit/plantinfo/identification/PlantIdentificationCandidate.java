package com.github.mdeluise.plantit.plantinfo.identification;

import java.util.List;

import com.github.mdeluise.plantit.botanicalinfo.BotanicalInfo;

public record PlantIdentificationCandidate(BotanicalInfo botanicalInfo, double confidence, double contextualScore,
                                           String modelVersion, PlantNetProject project,
                                           List<PlantIdentificationEvidence> evidence, String establishmentMeans,
                                           String establishmentPlace, List<PlantLookalike> reviewedLookalikes) {

    public PlantIdentificationCandidate {
        evidence = evidence == null ? List.of() : List.copyOf(evidence);
        reviewedLookalikes = reviewedLookalikes == null ? List.of() : List.copyOf(reviewedLookalikes);
    }


    public PlantIdentificationCandidate(BotanicalInfo botanicalInfo, double confidence, String modelVersion,
                                        PlantNetProject project) {
        this(botanicalInfo, confidence, confidence, modelVersion, project, List.of(), null, null, List.of());
    }
}
