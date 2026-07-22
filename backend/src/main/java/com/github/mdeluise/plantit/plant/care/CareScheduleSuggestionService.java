package com.github.mdeluise.plantit.plant.care;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.OptionalDouble;

import com.github.mdeluise.plantit.botanicalinfo.care.CareFieldProvenance;
import com.github.mdeluise.plantit.botanicalinfo.care.PlantCareInfo;
import com.github.mdeluise.plantit.diary.entry.DiaryEntry;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryRepository;
import com.github.mdeluise.plantit.diary.entry.DiaryEntryType;
import com.github.mdeluise.plantit.plant.Plant;
import com.github.mdeluise.plantit.plant.info.PlantInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class CareScheduleSuggestionService {
    private static final int MINIMUM_INTERVAL_DAYS = 2;
    private static final int MAXIMUM_INTERVAL_DAYS = 30;
    private static final int DEFAULT_INTERVAL_DAYS = 7;
    private static final int VERY_WET_SOIL_THRESHOLD = 9;
    private static final int VERY_WET_INTERVAL_DAYS = 3;
    private static final int WET_SOIL_THRESHOLD = 7;
    private static final int WET_INTERVAL_DAYS = 4;
    private static final int MODERATE_SOIL_THRESHOLD = 5;
    private static final int MODERATE_INTERVAL_DAYS = 7;
    private static final int DRY_SOIL_THRESHOLD = 3;
    private static final int DRY_INTERVAL_DAYS = 12;
    private static final int VERY_DRY_INTERVAL_DAYS = 18;
    private static final double OUTDOOR_FACTOR = 0.80;
    private static final double GREENHOUSE_FACTOR = 0.90;
    private static final double HIGH_LIGHT_FACTOR = 0.80;
    private static final double LOW_LIGHT_FACTOR = 1.25;
    private static final double SMALL_POT_MAXIMUM_CM = 12;
    private static final double SMALL_POT_FACTOR = 0.82;
    private static final double LARGE_POT_MINIMUM_CM = 30;
    private static final double LARGE_POT_FACTOR = 1.18;
    private static final double TERRACOTTA_FACTOR = 0.82;
    private static final double SELF_WATERING_FACTOR = 1.35;
    private static final double NO_DRAINAGE_FACTOR = 1.30;
    private static final double DRY_MIX_FACTOR = 1.20;
    private static final double MOISTURE_RETENTIVE_MIX_FACTOR = 1.12;
    private static final double DEFAULT_CONFIDENCE = 0.45;
    private static final double UNATTRIBUTED_CARE_CONFIDENCE = 0.60;
    private static final double PROFILE_CONFIDENCE_BONUS = 0.05;
    private static final double HISTORY_CONFIDENCE_BONUS = 0.05;
    private static final double HISTORY_BLEND = 0.35;
    private static final double MAXIMUM_CONFIDENCE = 0.95;
    private final DiaryEntryRepository diaryEntryRepository;


    @Autowired
    public CareScheduleSuggestionService(DiaryEntryRepository diaryEntryRepository) {
        this.diaryEntryRepository = diaryEntryRepository;
    }


    /**
     * Keeps isolated unit tests that only exercise the profile calculation independent from persistence.
     */
    public CareScheduleSuggestionService() {
        this(null);
    }


    public CareScheduleSuggestion suggest(Plant plant) {
        final PlantCareInfo care = plant.getBotanicalInfo().getPlantCareInfo();
        final PlantInfo profile = plant.getInfo();
        final List<String> factors = new ArrayList<>();
        double interval = baseInterval(care.getSoilHumidity());
        factors.add(care.getSoilHumidity() == null ? "DEFAULT_BASELINE" : "SPECIES_SOIL_MOISTURE");

        interval *= environmentFactor(profile, factors);
        interval *= lightFactor(profile, factors);
        interval *= potFactor(profile, factors);
        interval *= drainageFactor(profile, factors);
        interval *= soilFactor(profile, factors);
        final OptionalDouble observedInterval = recentWateringInterval(plant);
        if (observedInterval.isPresent()) {
            interval = interval * (1 - HISTORY_BLEND) + observedInterval.getAsDouble() * HISTORY_BLEND;
            factors.add("RECENT_WATERING_HISTORY");
        }

        final int roundedInterval = (int) Math.round(Math.max(
            MINIMUM_INTERVAL_DAYS, Math.min(MAXIMUM_INTERVAL_DAYS, interval)));
        return new CareScheduleSuggestion(
            roundedInterval,
            confidence(care, profile, observedInterval.isPresent()),
            List.copyOf(factors)
        );
    }


    private int baseInterval(Integer soilHumidity) {
        final int result;
        if (soilHumidity == null) {
            result = DEFAULT_INTERVAL_DAYS;
        } else if (soilHumidity >= VERY_WET_SOIL_THRESHOLD) {
            result = VERY_WET_INTERVAL_DAYS;
        } else if (soilHumidity >= WET_SOIL_THRESHOLD) {
            result = WET_INTERVAL_DAYS;
        } else if (soilHumidity >= MODERATE_SOIL_THRESHOLD) {
            result = MODERATE_INTERVAL_DAYS;
        } else if (soilHumidity >= DRY_SOIL_THRESHOLD) {
            result = DRY_INTERVAL_DAYS;
        } else {
            result = VERY_DRY_INTERVAL_DAYS;
        }
        return result;
    }


    private double environmentFactor(PlantInfo profile, List<String> factors) {
        return switch (normalize(profile.getGrowingEnvironment())) {
            case "OUTDOOR" -> addFactor(factors, "OUTDOOR", OUTDOOR_FACTOR);
            case "GREENHOUSE" -> addFactor(factors, "GREENHOUSE", GREENHOUSE_FACTOR);
            default -> 1;
        };
    }


    private double lightFactor(PlantInfo profile, List<String> factors) {
        return switch (normalize(profile.getLightExposure())) {
            case "HIGH" -> addFactor(factors, "HIGH_LIGHT", HIGH_LIGHT_FACTOR);
            case "LOW" -> addFactor(factors, "LOW_LIGHT", LOW_LIGHT_FACTOR);
            default -> 1;
        };
    }


    private double potFactor(PlantInfo profile, List<String> factors) {
        double result = 1;
        if (profile.getPotDiameterCm() != null && profile.getPotDiameterCm() <= SMALL_POT_MAXIMUM_CM) {
            result *= addFactor(factors, "SMALL_POT", SMALL_POT_FACTOR);
        } else if (profile.getPotDiameterCm() != null && profile.getPotDiameterCm() >= LARGE_POT_MINIMUM_CM) {
            result *= addFactor(factors, "LARGE_POT", LARGE_POT_FACTOR);
        }
        result *= switch (normalize(profile.getPotMaterial())) {
            case "TERRACOTTA" -> addFactor(factors, "TERRACOTTA", TERRACOTTA_FACTOR);
            case "SELF_WATERING" -> addFactor(factors, "SELF_WATERING", SELF_WATERING_FACTOR);
            default -> 1;
        };
        return result;
    }


    private double drainageFactor(PlantInfo profile, List<String> factors) {
        if (Boolean.FALSE.equals(profile.getHasDrainage())) {
            return addFactor(factors, "NO_DRAINAGE", NO_DRAINAGE_FACTOR);
        }
        return 1;
    }


    private double soilFactor(PlantInfo profile, List<String> factors) {
        final String soil = normalize(profile.getSoilType());
        if (soil.contains("CACTUS") || soil.contains("SUCCULENT")) {
            return addFactor(factors, "DRY_MIX", DRY_MIX_FACTOR);
        }
        if (soil.contains("COIR") || soil.contains("PEAT") || soil.contains("MOISTURE")) {
            return addFactor(factors, "MOISTURE_RETENTIVE_MIX", MOISTURE_RETENTIVE_MIX_FACTOR);
        }
        return 1;
    }


    private double confidence(PlantCareInfo care, PlantInfo profile, boolean hasHistory) {
        final CareFieldProvenance provenance = care.getFieldProvenance().get(PlantCareInfo.SOIL_HUMIDITY_FIELD);
        double result;
        if (provenance != null && provenance.getConfidence() != null) {
            result = provenance.getConfidence();
        } else {
            result = care.getSoilHumidity() == null ? DEFAULT_CONFIDENCE : UNATTRIBUTED_CARE_CONFIDENCE;
        }
        if (profile.getGrowingEnvironment() != null && profile.getLightExposure() != null) {
            result += PROFILE_CONFIDENCE_BONUS;
        }
        if (hasHistory) {
            result += HISTORY_CONFIDENCE_BONUS;
        }
        return Math.min(MAXIMUM_CONFIDENCE, result);
    }


    private OptionalDouble recentWateringInterval(Plant plant) {
        final List<DiaryEntry> entries = diaryEntryRepository == null || plant == null || plant.getId() == null
                                          ? List.of()
                                          : diaryEntryRepository.findTop4ByDiaryTargetAndTypeOrderByDateDesc(
                                              plant, DiaryEntryType.WATERING);
        if (entries == null || entries.size() < 2) {
            return OptionalDouble.empty();
        }
        final List<Long> intervals = new ArrayList<>();
        for (int index = 0; index < entries.size() - 1; index++) {
            final Date newer = entries.get(index).getDate();
            final Date older = entries.get(index + 1).getDate();
            if (newer == null || older == null || !newer.after(older)) {
                continue;
            }
            final long days = (newer.getTime() - older.getTime()) / (24L * 60L * 60L * 1000L);
            if (days >= MINIMUM_INTERVAL_DAYS && days <= MAXIMUM_INTERVAL_DAYS) {
                intervals.add(days);
            }
        }
        if (intervals.isEmpty()) {
            return OptionalDouble.empty();
        }
        return OptionalDouble.of(intervals.stream().mapToLong(Long::longValue).average().orElse(DEFAULT_INTERVAL_DAYS));
    }


    private double addFactor(List<String> factors, String factor, double value) {
        factors.add(factor);
        return value;
    }


    private String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }
}
