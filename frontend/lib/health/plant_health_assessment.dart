enum PlantHealthSymptom {
  wilting,
  yellowLeaves,
  brownCrispyEdges,
  darkOrWetSpots,
  paleOrLeggyGrowth,
  bleachedLeaves,
  visiblePestsOrWebbing,
  whitePowder,
}

enum ObservedSoilMoisture { wet, moist, dry, unknown }

enum ObservedPlantLight { low, moderate, bright, direct, unknown }

enum PlantHealthConcern {
  waterloggedRoots,
  droughtStress,
  pestPressure,
  leafSpotRisk,
  lowLightStress,
  excessLightStress,
  powderyMildewRisk,
  needsCloserInspection,
}

class PlantHealthAssessmentInput {
  final Set<PlantHealthSymptom> symptoms;
  final ObservedSoilMoisture soilMoisture;
  final ObservedPlantLight light;
  final bool poorAirflowOrWetLeaves;
  final bool recentMoveOrCareChange;

  const PlantHealthAssessmentInput({
    required this.symptoms,
    this.soilMoisture = ObservedSoilMoisture.unknown,
    this.light = ObservedPlantLight.unknown,
    this.poorAirflowOrWetLeaves = false,
    this.recentMoveOrCareChange = false,
  });
}

class PlantHealthAssessmentResult {
  final PlantHealthConcern concern;
  final int score;

  const PlantHealthAssessmentResult({
    required this.concern,
    required this.score,
  });
}

/// A deliberately conservative symptom sorter.
///
/// It ranks categories that the gardener should inspect next. It does not
/// diagnose a disease, inspect photo pixels, or recommend a pesticide.
class PlantHealthAssessment {
  static List<PlantHealthAssessmentResult> evaluate(
    PlantHealthAssessmentInput input,
  ) {
    final Map<PlantHealthConcern, int> scores = {
      for (final concern in PlantHealthConcern.values) concern: 0,
    };

    void add(PlantHealthConcern concern, int points) {
      scores[concern] = scores[concern]! + points;
    }

    if (input.symptoms.contains(PlantHealthSymptom.wilting)) {
      add(PlantHealthConcern.waterloggedRoots, 2);
      add(PlantHealthConcern.droughtStress, 2);
    }
    if (input.symptoms.contains(PlantHealthSymptom.yellowLeaves)) {
      add(PlantHealthConcern.waterloggedRoots, 3);
      add(PlantHealthConcern.lowLightStress, 1);
      add(PlantHealthConcern.pestPressure, 1);
    }
    if (input.symptoms.contains(PlantHealthSymptom.brownCrispyEdges)) {
      add(PlantHealthConcern.droughtStress, 3);
      add(PlantHealthConcern.excessLightStress, 1);
    }
    if (input.symptoms.contains(PlantHealthSymptom.darkOrWetSpots)) {
      add(PlantHealthConcern.leafSpotRisk, 5);
    }
    if (input.symptoms.contains(PlantHealthSymptom.paleOrLeggyGrowth)) {
      add(PlantHealthConcern.lowLightStress, 5);
    }
    if (input.symptoms.contains(PlantHealthSymptom.bleachedLeaves)) {
      add(PlantHealthConcern.excessLightStress, 5);
    }
    if (input.symptoms.contains(PlantHealthSymptom.visiblePestsOrWebbing)) {
      add(PlantHealthConcern.pestPressure, 8);
    }
    if (input.symptoms.contains(PlantHealthSymptom.whitePowder)) {
      add(PlantHealthConcern.powderyMildewRisk, 8);
    }

    switch (input.soilMoisture) {
      case ObservedSoilMoisture.wet:
        add(PlantHealthConcern.waterloggedRoots, 4);
        if (input.symptoms.contains(PlantHealthSymptom.darkOrWetSpots)) {
          add(PlantHealthConcern.leafSpotRisk, 2);
        }
      case ObservedSoilMoisture.dry:
        add(PlantHealthConcern.droughtStress, 4);
      case ObservedSoilMoisture.moist:
      case ObservedSoilMoisture.unknown:
        break;
    }

    switch (input.light) {
      case ObservedPlantLight.low:
        add(PlantHealthConcern.lowLightStress, 3);
      case ObservedPlantLight.direct:
        add(PlantHealthConcern.excessLightStress, 3);
      case ObservedPlantLight.bright:
      case ObservedPlantLight.moderate:
      case ObservedPlantLight.unknown:
        break;
    }

    if (input.poorAirflowOrWetLeaves) {
      add(PlantHealthConcern.leafSpotRisk, 3);
      add(PlantHealthConcern.powderyMildewRisk, 2);
    }
    if (input.recentMoveOrCareChange) {
      add(PlantHealthConcern.lowLightStress, 1);
      add(PlantHealthConcern.excessLightStress, 1);
      add(PlantHealthConcern.droughtStress, 1);
      add(PlantHealthConcern.waterloggedRoots, 1);
    }

    final List<PlantHealthAssessmentResult> ranked = scores.entries
        .where((entry) =>
            entry.key != PlantHealthConcern.needsCloserInspection &&
            entry.value >= 4)
        .map(
          (entry) => PlantHealthAssessmentResult(
            concern: entry.key,
            score: entry.value,
          ),
        )
        .toList()
      ..sort((left, right) {
        final int scoreOrder = right.score.compareTo(left.score);
        if (scoreOrder != 0) return scoreOrder;
        return left.concern.index.compareTo(right.concern.index);
      });

    if (ranked.isEmpty) {
      return const [
        PlantHealthAssessmentResult(
          concern: PlantHealthConcern.needsCloserInspection,
          score: 0,
        ),
      ];
    }
    return ranked.take(3).toList(growable: false);
  }
}
