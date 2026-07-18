class IdentificationContext {
  final DateTime? observedAt;
  final double? latitude;
  final double? longitude;
  final double? elevationMeters;
  final String? habitat;
  final String? region;

  const IdentificationContext({
    this.observedAt,
    this.latitude,
    this.longitude,
    this.elevationMeters,
    this.habitat,
    this.region,
  });

  Map<String, String> toQueryParameters() => {
        if (observedAt != null)
          'observedAt': observedAt!.toUtc().toIso8601String(),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        if (elevationMeters != null)
          'elevationMeters': elevationMeters.toString(),
        if (habitat != null && habitat!.trim().isNotEmpty)
          'habitat': habitat!.trim(),
        if (region != null && region!.trim().isNotEmpty)
          'region': region!.trim(),
      };
}
