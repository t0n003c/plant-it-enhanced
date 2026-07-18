package com.github.mdeluise.plantit.botanicalinfo.care;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.Map;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParseException;
import com.google.gson.JsonParser;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class CareFieldProvenanceMapConverter
        implements AttributeConverter<Map<String, CareFieldProvenance>, String> {

    @Override
    public String convertToDatabaseColumn(Map<String, CareFieldProvenance> attribute) {
        if (attribute == null || attribute.isEmpty()) {
            return null;
        }
        final JsonObject root = new JsonObject();
        attribute.forEach((field, provenance) -> root.add(field, toJson(provenance)));
        return root.toString();
    }


    @Override
    public Map<String, CareFieldProvenance> convertToEntityAttribute(String value) {
        final Map<String, CareFieldProvenance> result = new LinkedHashMap<>();
        if (value == null || value.isBlank()) {
            return result;
        }
        try {
            final JsonObject root = JsonParser.parseString(value).getAsJsonObject();
            root.entrySet().forEach(entry -> result.put(entry.getKey(), fromJson(entry.getValue())));
        } catch (JsonParseException | IllegalStateException | UnsupportedOperationException |
                 NumberFormatException exception) {
            return new LinkedHashMap<>();
        }
        return result;
    }


    private JsonObject toJson(CareFieldProvenance provenance) {
        final JsonObject result = new JsonObject();
        if (provenance != null) {
            add(result, "source", provenance.getSource());
            add(result, "sourceReference", provenance.getSourceReference());
            if (provenance.getConfidence() != null) {
                result.addProperty("confidence", provenance.getConfidence());
            }
            if (provenance.getVerifiedAt() != null) {
                result.addProperty("verifiedAt", provenance.getVerifiedAt().toString());
            }
        }
        return result;
    }


    private CareFieldProvenance fromJson(JsonElement element) {
        final JsonObject object = element != null && element.isJsonObject()
                                      ? element.getAsJsonObject() : new JsonObject();
        return new CareFieldProvenance(
            readString(object, "source"),
            readString(object, "sourceReference"),
            readDouble(object, "confidence"),
            readInstant(object, "verifiedAt")
        );
    }


    private void add(JsonObject object, String field, String value) {
        if (value != null) {
            object.addProperty(field, value);
        }
    }


    private String readString(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull()
                   ? object.get(field).getAsString() : null;
    }


    private Double readDouble(JsonObject object, String field) {
        return object.has(field) && !object.get(field).isJsonNull()
                   ? object.get(field).getAsDouble() : null;
    }


    private Instant readInstant(JsonObject object, String field) {
        final String value = readString(object, field);
        if (value == null) {
            return null;
        }
        try {
            return Instant.parse(value);
        } catch (DateTimeParseException exception) {
            return null;
        }
    }
}
