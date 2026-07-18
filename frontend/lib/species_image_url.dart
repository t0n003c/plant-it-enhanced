import 'package:plant_it/dto/species_dto.dart';

String? resolveSpeciesImageUrl(SpeciesDTO species, String? backendUrl) {
  if (_clean(backendUrl) == null) return null;
  final String? imageId = _clean(species.imageId);
  if (imageId != null) {
    return '${_normalizedBackendUrl(backendUrl)}image/content/${Uri.encodeComponent(imageId)}';
  }

  final String? remoteUrl = _clean(species.imageUrl);
  if (remoteUrl == null) return null;
  return buildImageProxyUrl(
    backendUrl,
    remoteUrl,
    fallbackUrl: _clean(species.imageFallbackUrl),
  );
}

String buildImageProxyUrl(
  String? backendUrl,
  String remoteUrl, {
  String? fallbackUrl,
}) {
  final Uri proxyUri = Uri.parse('${_normalizedBackendUrl(backendUrl)}proxy');
  final String? cleanedFallbackUrl = _clean(fallbackUrl);
  return proxyUri.replace(
    queryParameters: {
      'url': remoteUrl,
      if (cleanedFallbackUrl != null) 'fallbackUrl': cleanedFallbackUrl,
    },
  ).toString();
}

String missingSpeciesImageUrl(String? backendUrl) =>
    '${_normalizedBackendUrl(backendUrl)}image/content/non-existing-id';

String _normalizedBackendUrl(String? backendUrl) {
  final String value = _clean(backendUrl) ?? '';
  return value.endsWith('/') ? value : '$value/';
}

String? _clean(String? value) {
  final String? cleaned = value?.trim();
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}
