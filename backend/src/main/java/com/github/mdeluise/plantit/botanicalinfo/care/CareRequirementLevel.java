package com.github.mdeluise.plantit.botanicalinfo.care;

public enum CareRequirementLevel {
    LOW,
    MODERATE,
    HIGH;
    private static final int LOW_MAXIMUM = 3;
    private static final int MODERATE_MAXIMUM = 6;


    public static CareRequirementLevel fromScale(Integer value) {
        CareRequirementLevel result = null;
        if (value != null) {
            if (value <= LOW_MAXIMUM) {
                result = LOW;
            } else if (value <= MODERATE_MAXIMUM) {
                result = MODERATE;
            } else {
                result = HIGH;
            }
        }
        return result;
    }
}
