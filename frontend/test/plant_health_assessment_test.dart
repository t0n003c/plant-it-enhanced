import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/health/plant_health_assessment.dart';

void main() {
  test('ranks wet-soil yellowing and wilt as waterlogged-root stress', () {
    final results = PlantHealthAssessment.evaluate(
      const PlantHealthAssessmentInput(
        symptoms: {
          PlantHealthSymptom.wilting,
          PlantHealthSymptom.yellowLeaves,
        },
        soilMoisture: ObservedSoilMoisture.wet,
      ),
    );

    expect(results.first.concern, PlantHealthConcern.waterloggedRoots);
    expect(results.first.score, greaterThanOrEqualTo(8));
  });

  test('ranks dry-soil wilt and crispy margins as drought stress', () {
    final results = PlantHealthAssessment.evaluate(
      const PlantHealthAssessmentInput(
        symptoms: {
          PlantHealthSymptom.wilting,
          PlantHealthSymptom.brownCrispyEdges,
        },
        soilMoisture: ObservedSoilMoisture.dry,
      ),
    );

    expect(results.first.concern, PlantHealthConcern.droughtStress);
  });

  test('keeps direct pest and powder evidence as separate concerns', () {
    final results = PlantHealthAssessment.evaluate(
      const PlantHealthAssessmentInput(
        symptoms: {
          PlantHealthSymptom.visiblePestsOrWebbing,
          PlantHealthSymptom.whitePowder,
        },
      ),
    );

    expect(
      results.map((result) => result.concern),
      containsAll([
        PlantHealthConcern.pestPressure,
        PlantHealthConcern.powderyMildewRisk,
      ]),
    );
  });

  test('returns an honest closer-inspection state for weak evidence', () {
    final results = PlantHealthAssessment.evaluate(
      const PlantHealthAssessmentInput(symptoms: {}),
    );

    expect(results, hasLength(1));
    expect(
      results.single.concern,
      PlantHealthConcern.needsCloserInspection,
    );
  });
}
