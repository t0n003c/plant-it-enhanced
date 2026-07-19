package com.github.mdeluise.plantit.botanicalinfo.safety;

import java.time.Instant;
import java.util.List;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Reviewed human and pet safety guidance for a botanical result")
public record PlantSafetyInfo(
    @Schema(description = "Human ingestion or contact status") PlantSafetyStatus humanStatus,
    @Schema(description = "Cat exposure status") PlantSafetyStatus catStatus,
    @Schema(description = "Dog exposure status") PlantSafetyStatus dogStatus,
    @Schema(description = "Plain-language safety summary") String summary,
    @Schema(description = "Plant parts or related materials called out by the sources") List<String> hazardousParts,
    @Schema(description = "Sources supporting this profile") List<PlantSafetySource> sources,
    @Schema(description = "Catalog verification date") Instant lastVerifiedAt,
    @Schema(description = "Whether this taxon has been manually reviewed") boolean reviewed,
    @Schema(description = "Exact taxon or broader taxonomic group used for the match") String matchedTaxon
) {
    public static PlantSafetyInfo unknown() {
        return new PlantSafetyInfo(
            PlantSafetyStatus.UNKNOWN,
            PlantSafetyStatus.UNKNOWN,
            PlantSafetyStatus.UNKNOWN,
            null,
            List.of(),
            List.of(),
            null,
            false,
            null
        );
    }
}
