import 'dart:typed_data';

enum TrailSyncState {
  pending,
  syncing,
  failed,
  synced;

  static TrailSyncState parse(String? value) {
    return TrailSyncState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => TrailSyncState.pending,
    );
  }
}

class OfflineObservationPhoto {
  final String localId;
  final String name;
  final String contentType;
  final String organ;
  final Uint8List bytes;
  String? serverImageId;

  OfflineObservationPhoto({
    required this.localId,
    required this.name,
    required this.contentType,
    required this.organ,
    required this.bytes,
    this.serverImageId,
  });

  factory OfflineObservationPhoto.fromStorageMap(Map<String, dynamic> map) {
    final dynamic storedBytes = map['bytes'];
    return OfflineObservationPhoto(
      localId: map['localId'] as String,
      name: map['name'] as String,
      contentType: map['contentType'] as String? ?? 'image/jpeg',
      organ: map['organ'] as String? ?? 'auto',
      bytes: storedBytes is Uint8List
          ? storedBytes
          : Uint8List.fromList((storedBytes as List<dynamic>).cast<int>()),
      serverImageId: map['serverImageId'] as String?,
    );
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'localId': localId,
      'name': name,
      'contentType': contentType,
      'organ': organ,
      'bytes': bytes,
      if (serverImageId != null) 'serverImageId': serverImageId,
    };
  }
}

class OfflineObservationDraft {
  final String localId;
  final String accountScope;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime observedAt;
  int? serverObservationId;
  int? botanicalInfoId;
  Map<String, dynamic>? selectedTaxon;
  String? displayName;
  String? trailName;
  String? habitat;
  String? notes;
  double? latitude;
  double? longitude;
  double? accuracyMeters;
  double? elevationMeters;
  String locationPrivacy;
  String status;
  double? identificationConfidence;
  String? identificationProvider;
  String? hikeSessionLocalId;
  int? hikeSessionId;
  String? hikeSessionName;
  List<OfflineObservationPhoto> photos;
  TrailSyncState syncState;
  String? lastError;
  int retryCount;
  DateTime? lastAttemptAt;

  OfflineObservationDraft({
    required this.localId,
    required this.accountScope,
    required this.createdAt,
    required this.updatedAt,
    required this.observedAt,
    required this.photos,
    this.serverObservationId,
    this.botanicalInfoId,
    this.selectedTaxon,
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
    this.hikeSessionLocalId,
    this.hikeSessionId,
    this.hikeSessionName,
    this.syncState = TrailSyncState.pending,
    this.lastError,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  factory OfflineObservationDraft.fromStorageMap(Map<String, dynamic> map) {
    final TrailSyncState storedState =
        TrailSyncState.parse(map['syncState'] as String?);
    final dynamic taxon = map['selectedTaxon'];
    return OfflineObservationDraft(
      localId: map['localId'] as String,
      accountScope: map['accountScope'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      observedAt: DateTime.parse(map['observedAt'] as String),
      serverObservationId: (map['serverObservationId'] as num?)?.toInt(),
      botanicalInfoId: (map['botanicalInfoId'] as num?)?.toInt(),
      selectedTaxon:
          taxon == null ? null : Map<String, dynamic>.from(taxon as Map),
      displayName: map['displayName'] as String?,
      trailName: map['trailName'] as String?,
      habitat: map['habitat'] as String?,
      notes: map['notes'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      elevationMeters: (map['elevationMeters'] as num?)?.toDouble(),
      locationPrivacy: map['locationPrivacy'] as String? ?? 'PRIVATE',
      status: map['status'] as String? ?? 'UNIDENTIFIED',
      identificationConfidence:
          (map['identificationConfidence'] as num?)?.toDouble(),
      identificationProvider: map['identificationProvider'] as String?,
      hikeSessionLocalId: map['hikeSessionLocalId'] as String?,
      hikeSessionId: (map['hikeSessionId'] as num?)?.toInt(),
      hikeSessionName: map['hikeSessionName'] as String?,
      photos: (map['photos'] as List<dynamic>? ?? [])
          .map(
            (photo) => OfflineObservationPhoto.fromStorageMap(
              Map<String, dynamic>.from(photo as Map),
            ),
          )
          .toList(),
      syncState: storedState == TrailSyncState.syncing
          ? TrailSyncState.failed
          : storedState,
      lastError: storedState == TrailSyncState.syncing
          ? 'The previous sync was interrupted.'
          : map['lastError'] as String?,
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: map['lastAttemptAt'] == null
          ? null
          : DateTime.parse(map['lastAttemptAt'] as String),
    );
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'localId': localId,
      'accountScope': accountScope,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'observedAt': observedAt.toUtc().toIso8601String(),
      if (serverObservationId != null)
        'serverObservationId': serverObservationId,
      if (botanicalInfoId != null) 'botanicalInfoId': botanicalInfoId,
      if (selectedTaxon != null) 'selectedTaxon': selectedTaxon,
      if (displayName != null) 'displayName': displayName,
      if (trailName != null) 'trailName': trailName,
      if (habitat != null) 'habitat': habitat,
      if (notes != null) 'notes': notes,
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
      if (hikeSessionLocalId != null) 'hikeSessionLocalId': hikeSessionLocalId,
      if (hikeSessionId != null) 'hikeSessionId': hikeSessionId,
      if (hikeSessionName != null) 'hikeSessionName': hikeSessionName,
      'photos': photos.map((photo) => photo.toStorageMap()).toList(),
      'syncState': syncState.name,
      if (lastError != null) 'lastError': lastError,
      'retryCount': retryCount,
      if (lastAttemptAt != null)
        'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toObservationMap() {
    return {
      'clientReference': localId,
      if (botanicalInfoId != null) 'botanicalInfoId': botanicalInfoId,
      if (hikeSessionId != null) 'hikeSessionId': hikeSessionId,
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
}
