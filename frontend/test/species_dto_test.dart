import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/dto/species_dto.dart';

void main() {
  test('parses synonyms and structured common names without brackets', () {
    final species = SpeciesDTO.fromJson({
      'id': null,
      'scientificName': 'Dracaena trifasciata',
      'synonyms': ['Sansevieria trifasciata', 'snake plant'],
      'preferredCommonName': 'Snake Plant',
      'commonNames': [
        {
          'name': 'Snake Plant',
          'language': 'en',
          'region': 'US',
          'preferred': true,
          'source': 'INATURALIST',
        },
        {
          'name': 'Lengua de suegra',
          'language': 'es',
          'region': 'MX',
          'preferred': true,
          'source': 'INATURALIST',
        }
      ],
      'externalReferences': {
        'INATURALIST': '67710',
        'GBIF': '11041822',
      },
      'canonicalTaxonKey': '11041822',
      'lastVerifiedAt': '2026-07-17T12:00:00Z',
      'family': 'Asparagaceae',
      'genus': 'Dracaena',
      'species': 'Dracaena trifasciata',
      'plantCareInfo': <String, dynamic>{},
      'creator': 'INATURALIST',
      'externalId': '67710',
    });

    expect(species.synonyms, ['Sansevieria trifasciata', 'snake plant']);
    expect(species.preferredCommonName, 'Snake Plant');
    expect(species.commonNames.first.name, 'Snake Plant');
    expect(species.externalReferences['GBIF'], '11041822');
    expect(species.canonicalTaxonKey, '11041822');
    expect(
        species.preferredCommonNameFor('es', region: 'MX'), 'Lengua de suegra');
    expect(species.preferredCommonNameFor('en', region: 'US'), 'Snake Plant');
    expect(species.toMap()['synonyms'],
        ['Sansevieria trifasciata', 'snake plant']);
  });
}
