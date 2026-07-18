package com.github.mdeluise.plantit.plantinfo.identification;

/**
 * One attributable signal shown alongside a photo-identification candidate.
 */
public record PlantIdentificationEvidence(String code, double adjustment, String source,
                                          String sourceReference, Integer observationCount, String detail) {
}
