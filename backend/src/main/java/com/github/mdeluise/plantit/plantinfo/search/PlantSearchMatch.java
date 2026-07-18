package com.github.mdeluise.plantit.plantinfo.search;

public record PlantSearchMatch(int score, double confidence, PlantSearchMatchReason reason) {
    private static final double MINIMUM_RELEVANCE = 0.50;


    public boolean isRelevant() {
        return score > 0 && confidence >= MINIMUM_RELEVANCE;
    }
}
