package com.github.mdeluise.plantit.unit.component;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import com.github.mdeluise.plantit.botanicalinfo.care.CareFieldProvenance;
import com.github.mdeluise.plantit.botanicalinfo.care.CareFieldProvenanceMapConverter;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Unit tests for per-field care provenance persistence")
class CareFieldProvenanceMapConverterUnitTests {
    private final CareFieldProvenanceMapConverter converter = new CareFieldProvenanceMapConverter();


    @Test
    @DisplayName("Should preserve source, reference, confidence, and verification time")
    void shouldRoundTripProvenance() {
        final Instant verifiedAt = Instant.parse("2026-07-17T12:00:00Z");
        final Map<String, CareFieldProvenance> provenance = new LinkedHashMap<>();
        provenance.put("light", new CareFieldProvenance(
            "TREFLE", "monstera-deliciosa", 0.90, verifiedAt));
        provenance.put("soilHumidity", new CareFieldProvenance(
            "CURATED_CATALOG", "https://plants.ces.ncsu.edu/", 0.88, verifiedAt));

        final Map<String, CareFieldProvenance> restored = converter.convertToEntityAttribute(
            converter.convertToDatabaseColumn(provenance));

        Assertions.assertEquals(provenance.keySet(), restored.keySet());
        assertProvenance(restored.get("light"), "TREFLE", "monstera-deliciosa", 0.90, verifiedAt);
        assertProvenance(
            restored.get("soilHumidity"), "CURATED_CATALOG",
            "https://plants.ces.ncsu.edu/", 0.88, verifiedAt);
    }


    @Test
    @DisplayName("Should recover safely from legacy or malformed values")
    void shouldHandleMalformedLegacyValue() {
        Assertions.assertTrue(converter.convertToEntityAttribute("not-json").isEmpty());
        Assertions.assertTrue(converter.convertToEntityAttribute(null).isEmpty());
    }


    private void assertProvenance(CareFieldProvenance actual, String source, String reference,
                                  double confidence, Instant verifiedAt) {
        Assertions.assertNotNull(actual);
        Assertions.assertEquals(source, actual.getSource());
        Assertions.assertEquals(reference, actual.getSourceReference());
        Assertions.assertEquals(confidence, actual.getConfidence());
        Assertions.assertEquals(verifiedAt, actual.getVerifiedAt());
    }
}
