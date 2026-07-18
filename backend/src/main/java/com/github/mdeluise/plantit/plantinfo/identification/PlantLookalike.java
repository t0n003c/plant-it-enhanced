package com.github.mdeluise.plantit.plantinfo.identification;

/**
 * A reviewed comparison between an identification candidate and a commonly confused taxon.
 */
public record PlantLookalike(String scientificName, String commonName, String comparison,
                             String source, String sourceReference, boolean contactHazard) {
}
