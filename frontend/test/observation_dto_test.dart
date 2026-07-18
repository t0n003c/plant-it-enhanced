import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/dto/observation_dto.dart';

void main() {
  test('observation JSON keeps private location and identification metadata',
      () {
    final observation = ObservationDTO.fromJson({
      'id': 12,
      'ownerId': 4,
      'botanicalInfoId': 9,
      'scientificName': 'Monarda fistulosa',
      'preferredCommonName': 'Wild bergamot',
      'observedAt': '2026-07-18T03:15:00Z',
      'createdAt': '2026-07-18T03:16:00Z',
      'updatedAt': '2026-07-18T03:16:00Z',
      'latitude': 41.88,
      'longitude': -87.63,
      'accuracyMeters': 8.5,
      'locationPrivacy': 'PRIVATE',
      'status': 'CONFIRMED',
      'identificationConfidence': .91,
      'identificationProvider': 'plantnet',
      'imageIds': ['whole', 'leaf'],
    });

    expect(observation.bestDisplayName, 'Wild bergamot');
    expect(observation.locationPrivacy, 'PRIVATE');
    expect(observation.imageIds, ['whole', 'leaf']);
    expect(observation.toMap()['latitude'], 41.88);
    expect(observation.toMap()['status'], 'CONFIRMED');
  });

  test('unidentified observation has a safe display fallback', () {
    final observation = ObservationDTO.fromJson({
      'observedAt': '2026-07-18T03:15:00Z',
      'locationPrivacy': 'PRIVATE',
      'status': 'UNIDENTIFIED',
    });

    expect(observation.bestDisplayName, 'Unidentified trail find');
    expect(observation.toMap().containsKey('botanicalInfoId'), isFalse);
  });
}
