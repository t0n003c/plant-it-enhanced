package com.github.mdeluise.plantit.plantinfo.identification;

public final class IdentificationLocationPrivacy {
    private IdentificationLocationPrivacy() {
    }


    public static CoarsenedLocation coarsen(PlantIdentificationContext context, double precisionDegrees) {
        if (context == null || !context.hasCoordinates()) {
            throw new IllegalArgumentException("Coordinates are required");
        }
        final double precision = Math.max(0.1, precisionDegrees);
        return new CoarsenedLocation(
            Math.round(context.latitude() / precision) * precision,
            Math.round(context.longitude() / precision) * precision
        );
    }


    public record CoarsenedLocation(double latitude, double longitude) {
    }
}
