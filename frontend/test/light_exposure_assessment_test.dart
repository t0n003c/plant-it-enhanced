import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/care/light_exposure_assessment.dart';

void main() {
  test('estimates a blocked distant location as low light', () {
    final result = LightExposureAssessment.evaluate(
      const LightExposureInput(
        directLight: NaturalLightDuration.none,
        distance: WindowDistance.far,
        obstruction: WindowObstruction.blocked,
      ),
    );

    expect(result.estimatedLevel, EstimatedLightLevel.low);
    expect(result.score, 0);
  });

  test('estimates several open-window sun hours as high light', () {
    final result = LightExposureAssessment.evaluate(
      const LightExposureInput(
        directLight: NaturalLightDuration.twoToFourHours,
        distance: WindowDistance.near,
        obstruction: WindowObstruction.open,
      ),
      requiredLevel: 'HIGH',
    );

    expect(result.estimatedLevel, EstimatedLightLevel.high);
    expect(result.match, LightPlacementMatch.suitable);
  });

  test('compares estimated and reviewed requirements in both directions', () {
    final tooLow = LightExposureAssessment.evaluate(
      const LightExposureInput(
        directLight: NaturalLightDuration.underTwoHours,
        distance: WindowDistance.middle,
        obstruction: WindowObstruction.filtered,
      ),
      requiredLevel: 'MEDIUM',
    );
    final tooHigh = LightExposureAssessment.evaluate(
      const LightExposureInput(
        directLight: NaturalLightDuration.overFourHours,
        distance: WindowDistance.near,
        obstruction: WindowObstruction.open,
      ),
      requiredLevel: 'LOW',
    );

    expect(tooLow.match, LightPlacementMatch.tooLow);
    expect(tooHigh.match, LightPlacementMatch.tooHigh);
  });
}
