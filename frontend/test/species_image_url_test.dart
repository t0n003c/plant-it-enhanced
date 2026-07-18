import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/species_image_url.dart';

void main() {
  test('prefers a stored image id over a remote provider URL', () {
    final SpeciesDTO species = createSpecies(
      imageId: 'saved image',
      imageUrl: 'https://example.org/remote.jpg',
    );

    expect(
      resolveSpeciesImageUrl(species, 'https://nas.example/api/'),
      'https://nas.example/api/image/content/saved%20image',
    );
  });

  test('encodes primary and fallback provider URLs as proxy parameters', () {
    const String primary = 'https://example.org/medium.jpg?token=a&size=500';
    const String fallback = 'https://example.org/square.jpg?token=b&size=75';
    final SpeciesDTO species = createSpecies(
      imageUrl: primary,
      imageFallbackUrl: fallback,
    );

    final String? result =
        resolveSpeciesImageUrl(species, 'https://nas.example/api');
    final Uri proxyUri = Uri.parse(result!);

    expect(proxyUri.path, '/api/proxy');
    expect(proxyUri.queryParameters['url'], primary);
    expect(proxyUri.queryParameters['fallbackUrl'], fallback);
  });

  test('returns no URL for an image-less species', () {
    expect(
      resolveSpeciesImageUrl(
        createSpecies(),
        'https://nas.example/api/',
      ),
      isNull,
    );
  });
}

SpeciesDTO createSpecies({
  String? imageId,
  String? imageUrl,
  String? imageFallbackUrl,
}) {
  return SpeciesDTO(
    scientificName: 'Monstera deliciosa',
    care: SpeciesCareInfoDTO(),
    creator: 'INATURALIST',
    imageId: imageId,
    imageUrl: imageUrl,
    imageFallbackUrl: imageFallbackUrl,
  );
}
