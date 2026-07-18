import 'package:plant_it/observation/offline_observation_draft.dart';

class OfflineHikeSession {
  final String localId;
  final String accountScope;
  int? serverId;
  String name;
  DateTime startedAt;
  DateTime? endedAt;
  String? notes;
  TrailSyncState syncState;
  String? lastError;
  int retryCount;
  DateTime updatedAt;

  OfflineHikeSession({
    required this.localId,
    required this.accountScope,
    required this.name,
    required this.startedAt,
    required this.updatedAt,
    this.serverId,
    this.endedAt,
    this.notes,
    this.syncState = TrailSyncState.pending,
    this.lastError,
    this.retryCount = 0,
  });

  bool get isActive => endedAt == null;

  factory OfflineHikeSession.fromStorageMap(Map<String, dynamic> map) {
    final TrailSyncState storedState =
        TrailSyncState.parse(map['syncState'] as String?);
    return OfflineHikeSession(
      localId: map['localId'] as String,
      accountScope: map['accountScope'] as String,
      serverId: (map['serverId'] as num?)?.toInt(),
      name: map['name'] as String,
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: map['endedAt'] == null
          ? null
          : DateTime.parse(map['endedAt'] as String),
      notes: map['notes'] as String?,
      syncState: storedState == TrailSyncState.syncing
          ? TrailSyncState.failed
          : storedState,
      lastError: storedState == TrailSyncState.syncing
          ? 'The previous sync was interrupted.'
          : map['lastError'] as String?,
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'localId': localId,
      'accountScope': accountScope,
      if (serverId != null) 'serverId': serverId,
      'name': name,
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
      if (notes != null) 'notes': notes,
      'syncState': syncState.name,
      if (lastError != null) 'lastError': lastError,
      'retryCount': retryCount,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toServerMap() {
    return {
      'name': name.trim(),
      'startedAt': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
      if (notes?.trim().isNotEmpty == true) 'notes': notes!.trim(),
      'clientReference': localId,
    };
  }
}
