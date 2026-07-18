class ObservationDTO {
  final int? id;
  final int? ownerId;
  final int? botanicalInfoId;
  final int? hikeSessionId;
  final String? hikeSessionName;
  final String? scientificName;
  final String? preferredCommonName;
  final DateTime observedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? displayName;
  final String? trailName;
  final String? habitat;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final double? elevationMeters;
  final String locationPrivacy;
  final String status;
  final double? identificationConfidence;
  final String? identificationProvider;
  final String? clientReference;
  final List<String> imageIds;

  const ObservationDTO({
    this.id,
    this.ownerId,
    this.botanicalInfoId,
    this.hikeSessionId,
    this.hikeSessionName,
    this.scientificName,
    this.preferredCommonName,
    required this.observedAt,
    this.createdAt,
    this.updatedAt,
    this.displayName,
    this.trailName,
    this.habitat,
    this.notes,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.elevationMeters,
    this.locationPrivacy = 'PRIVATE',
    this.status = 'UNIDENTIFIED',
    this.identificationConfidence,
    this.identificationProvider,
    this.clientReference,
    this.imageIds = const [],
  });

  factory ObservationDTO.fromJson(Map<String, dynamic> json) {
    return ObservationDTO(
      id: json['id'] as int?,
      ownerId: json['ownerId'] as int?,
      botanicalInfoId: json['botanicalInfoId'] as int?,
      hikeSessionId: json['hikeSessionId'] as int?,
      hikeSessionName: json['hikeSessionName'] as String?,
      scientificName: json['scientificName'] as String?,
      preferredCommonName: json['preferredCommonName'] as String?,
      observedAt: DateTime.parse(json['observedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      displayName: json['displayName'] as String?,
      trailName: json['trailName'] as String?,
      habitat: json['habitat'] as String?,
      notes: json['notes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      elevationMeters: (json['elevationMeters'] as num?)?.toDouble(),
      locationPrivacy: json['locationPrivacy'] as String? ?? 'PRIVATE',
      status: json['status'] as String? ?? 'UNIDENTIFIED',
      identificationConfidence:
          (json['identificationConfidence'] as num?)?.toDouble(),
      identificationProvider: json['identificationProvider'] as String?,
      clientReference: json['clientReference'] as String?,
      imageIds: (json['imageIds'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (botanicalInfoId != null) 'botanicalInfoId': botanicalInfoId,
      if (hikeSessionId != null) 'hikeSessionId': hikeSessionId,
      if (clientReference != null) 'clientReference': clientReference,
      'observedAt': observedAt.toUtc().toIso8601String(),
      if (displayName?.trim().isNotEmpty == true)
        'displayName': displayName!.trim(),
      if (trailName?.trim().isNotEmpty == true) 'trailName': trailName!.trim(),
      if (habitat?.trim().isNotEmpty == true) 'habitat': habitat!.trim(),
      if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (elevationMeters != null) 'elevationMeters': elevationMeters,
      'locationPrivacy': locationPrivacy,
      'status': status,
      if (identificationConfidence != null)
        'identificationConfidence': identificationConfidence,
      if (identificationProvider != null)
        'identificationProvider': identificationProvider,
    };
  }

  String get bestDisplayName {
    for (final String? candidate in [
      displayName,
      preferredCommonName,
      scientificName,
    ]) {
      if (candidate?.trim().isNotEmpty == true) return candidate!.trim();
    }
    return 'Unidentified trail find';
  }
}
