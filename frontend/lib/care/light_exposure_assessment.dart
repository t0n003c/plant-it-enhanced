enum NaturalLightDuration { none, underTwoHours, twoToFourHours, overFourHours }

enum WindowDistance { near, middle, far }

enum WindowObstruction { open, filtered, blocked }

enum EstimatedLightLevel { low, moderate, high }

enum LightPlacementMatch { tooLow, suitable, tooHigh, unknownRequirement }

class LightExposureInput {
  final NaturalLightDuration directLight;
  final WindowDistance distance;
  final WindowObstruction obstruction;

  const LightExposureInput({
    required this.directLight,
    required this.distance,
    required this.obstruction,
  });
}

class LightExposureResult {
  final EstimatedLightLevel estimatedLevel;
  final LightPlacementMatch match;
  final int score;

  const LightExposureResult({
    required this.estimatedLevel,
    required this.match,
    required this.score,
  });
}

/// Estimates a broad light category from observable placement details.
///
/// This intentionally avoids lux/PAR claims because a browser camera is not a
/// calibrated light meter. The estimate is meant to support a placement check,
/// not replace a horticultural meter.
class LightExposureAssessment {
  static LightExposureResult evaluate(
    LightExposureInput input, {
    String? requiredLevel,
  }) {
    int score = switch (input.directLight) {
      NaturalLightDuration.none => 0,
      NaturalLightDuration.underTwoHours => 2,
      NaturalLightDuration.twoToFourHours => 4,
      NaturalLightDuration.overFourHours => 6,
    };

    score += switch (input.distance) {
      WindowDistance.near => 2,
      WindowDistance.middle => 0,
      WindowDistance.far => -2,
    };
    score += switch (input.obstruction) {
      WindowObstruction.open => 1,
      WindowObstruction.filtered => 0,
      WindowObstruction.blocked => -2,
    };

    final int boundedScore = score.clamp(0, 9);
    final EstimatedLightLevel estimatedLevel = switch (boundedScore) {
      <= 2 => EstimatedLightLevel.low,
      <= 5 => EstimatedLightLevel.moderate,
      _ => EstimatedLightLevel.high,
    };
    final EstimatedLightLevel? requirement = switch (requiredLevel) {
      'LOW' => EstimatedLightLevel.low,
      'MEDIUM' || 'MODERATE' => EstimatedLightLevel.moderate,
      'HIGH' => EstimatedLightLevel.high,
      _ => null,
    };
    final LightPlacementMatch match;
    if (requirement == null) {
      match = LightPlacementMatch.unknownRequirement;
    } else if (estimatedLevel.index < requirement.index) {
      match = LightPlacementMatch.tooLow;
    } else if (estimatedLevel.index > requirement.index) {
      match = LightPlacementMatch.tooHigh;
    } else {
      match = LightPlacementMatch.suitable;
    }

    return LightExposureResult(
      estimatedLevel: estimatedLevel,
      match: match,
      score: boundedScore,
    );
  }
}
