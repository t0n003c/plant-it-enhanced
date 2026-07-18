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
      'imageUrl': 'https://example.org/medium.jpg',
      'imageFallbackUrl': 'https://example.org/square.jpg',
      'imageSource': 'INATURALIST',
      'imageSourceUrl': 'https://www.inaturalist.org/photos/12345',
      'imageLicenseCode': 'cc-by',
      'imageAttribution': '(c) Example Photographer, CC BY',
      'creator': 'INATURALIST',
      'externalId': '67710',
      'identificationConfidence': 0.82,
      'contextualIdentificationScore': 0.94,
      'identificationEvidence': [
        {
          'code': 'NEARBY_SEASONAL_OCCURRENCES',
          'adjustment': 0.1,
          'source': 'iNaturalist',
          'sourceReference': 'https://www.inaturalist.org/observations',
          'observationCount': 42,
          'detail': '6,7,8',
        }
      ],
      'reviewedLookalikes': [
        {
          'scientificName': 'Parthenocissus quinquefolia',
          'commonName': 'Virginia creeper',
          'comparison': 'Usually five leaflets instead of three.',
          'source': 'U.S. National Park Service',
          'sourceReference': 'https://www.nps.gov/example',
          'contactHazard': false,
        }
      ],
      'establishmentMeans': 'native',
      'establishmentPlace': 'United States',
      'catalogTags': ['NORTH_AMERICAN_TRAIL'],
    });

    expect(species.synonyms, ['Sansevieria trifasciata', 'snake plant']);
    expect(species.preferredCommonName, 'Snake Plant');
    expect(species.commonNames.first.name, 'Snake Plant');
    expect(species.externalReferences['GBIF'], '11041822');
    expect(species.canonicalTaxonKey, '11041822');
    expect(species.catalogTags, ['NORTH_AMERICAN_TRAIL']);
    expect(species.imageFallbackUrl, 'https://example.org/square.jpg');
    expect(species.imageSource, 'INATURALIST');
    expect(species.imageLicenseCode, 'cc-by');
    expect(species.imageAttribution, '(c) Example Photographer, CC BY');
    expect(species.identificationConfidence, 0.82);
    expect(species.contextualIdentificationScore, 0.94);
    expect(species.identificationEvidence.single.observationCount, 42);
    expect(species.reviewedLookalikes.single.commonName, 'Virginia creeper');
    expect(species.reviewedLookalikes.single.contactHazard, isFalse);
    expect(species.establishmentMeans, 'native');
    expect(species.establishmentPlace, 'United States');
    expect(
        species.preferredCommonNameFor('es', region: 'MX'), 'Lengua de suegra');
    expect(species.preferredCommonNameFor('en', region: 'US'), 'Snake Plant');
    expect(species.toMap()['synonyms'],
        ['Sansevieria trifasciata', 'snake plant']);
    expect(species.toMap()['catalogTags'], ['NORTH_AMERICAN_TRAIL']);
    expect(species.toMap()['imageSourceUrl'],
        'https://www.inaturalist.org/photos/12345');
    expect(species.toMap()['contextualIdentificationScore'], 0.94);
    expect(
      species.toMap()['identificationEvidence'],
      [
        {
          'code': 'NEARBY_SEASONAL_OCCURRENCES',
          'adjustment': 0.1,
          'source': 'iNaturalist',
          'sourceReference': 'https://www.inaturalist.org/observations',
          'observationCount': 42,
          'detail': '6,7,8',
        }
      ],
    );
    expect(
      species.toMap()['reviewedLookalikes'],
      [
        {
          'scientificName': 'Parthenocissus quinquefolia',
          'commonName': 'Virginia creeper',
          'comparison': 'Usually five leaflets instead of three.',
          'source': 'U.S. National Park Service',
          'sourceReference': 'https://www.nps.gov/example',
          'contactHazard': false,
        }
      ],
    );
  });
}
