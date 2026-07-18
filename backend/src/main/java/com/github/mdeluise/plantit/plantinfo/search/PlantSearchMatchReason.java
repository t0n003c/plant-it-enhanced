package com.github.mdeluise.plantit.plantinfo.search;

public enum PlantSearchMatchReason {
    EXACT_COMMON_NAME,
    COMMON_NAME_PREFIX,
    COMMON_NAME_KEYWORDS,
    COMMON_NAME_TYPO,
    SCIENTIFIC_NAME,
    SCIENTIFIC_SYNONYM,
    PARTIAL_MATCH,
    NONE,
}
