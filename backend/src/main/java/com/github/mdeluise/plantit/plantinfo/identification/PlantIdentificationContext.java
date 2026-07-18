package com.github.mdeluise.plantit.plantinfo.identification;

import java.time.Instant;

/**
 * Optional field context supplied by the user for an identification request.
 */
public record PlantIdentificationContext(Double latitude, Double longitude, Double elevationMeters,
                                         String habitat, Instant observedAt, String region) {

    public PlantIdentificationContext {
        if ((latitude == null) != (longitude == null)) {
            throw new IllegalArgumentException("Latitude and longitude must be supplied together");
        }
        if (latitude != null && (latitude < -90 || latitude > 90)) {
            throw new IllegalArgumentException("Latitude must be between -90 and 90");
        }
        if (longitude != null && (longitude < -180 || longitude > 180)) {
            throw new IllegalArgumentException("Longitude must be between -180 and 180");
        }
    }


    public static PlantIdentificationContext empty() {
        return new PlantIdentificationContext(null, null, null, null, null, null);
    }


    public boolean hasCoordinates() {
        return latitude != null && longitude != null;
    }
}
