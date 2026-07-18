import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:plant_it/observation/offline_hike_session.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';

abstract class TrailDraftRepository {
  Future<List<OfflineObservationDraft>> listObservationDrafts(
    String accountScope,
  );

  Future<OfflineObservationDraft?> getObservationDraft(
    String accountScope,
    String localId,
  );

  Future<void> saveObservationDraft(OfflineObservationDraft draft);

  Future<void> deleteObservationDraft(
    String accountScope,
    String localId,
  );

  Future<List<OfflineHikeSession>> listHikeSessions(String accountScope);

  Future<OfflineHikeSession?> getHikeSession(
    String accountScope,
    String localId,
  );

  Future<OfflineHikeSession?> getActiveHikeSession(String accountScope);

  Future<void> saveHikeSession(OfflineHikeSession session);

  Future<void> deleteHikeSession(String accountScope, String localId);
}

class MemoryTrailDraftRepository implements TrailDraftRepository {
  final Map<String, OfflineObservationDraft> _observations = {};
  final Map<String, OfflineHikeSession> _sessions = {};

  String _key(String accountScope, String localId) => '$accountScope::$localId';

  @override
  Future<void> deleteObservationDraft(
    String accountScope,
    String localId,
  ) async {
    _observations.remove(_key(accountScope, localId));
  }

  @override
  Future<OfflineObservationDraft?> getObservationDraft(
    String accountScope,
    String localId,
  ) async {
    return _observations[_key(accountScope, localId)];
  }

  @override
  Future<List<OfflineObservationDraft>> listObservationDrafts(
    String accountScope,
  ) async {
    final drafts = _observations.values
        .where((draft) => draft.accountScope == accountScope)
        .toList();
    drafts.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return drafts;
  }

  @override
  Future<void> saveObservationDraft(OfflineObservationDraft draft) async {
    _observations[_key(draft.accountScope, draft.localId)] = draft;
  }

  @override
  Future<void> deleteHikeSession(
    String accountScope,
    String localId,
  ) async {
    _sessions.remove(_key(accountScope, localId));
  }

  @override
  Future<OfflineHikeSession?> getActiveHikeSession(
    String accountScope,
  ) async {
    final sessions = await listHikeSessions(accountScope);
    for (final session in sessions) {
      if (session.isActive) return session;
    }
    return null;
  }

  @override
  Future<OfflineHikeSession?> getHikeSession(
    String accountScope,
    String localId,
  ) async {
    return _sessions[_key(accountScope, localId)];
  }

  @override
  Future<List<OfflineHikeSession>> listHikeSessions(
    String accountScope,
  ) async {
    final sessions = _sessions.values
        .where((session) => session.accountScope == accountScope)
        .toList();
    sessions.sort((left, right) => right.startedAt.compareTo(left.startedAt));
    return sessions;
  }

  @override
  Future<void> saveHikeSession(OfflineHikeSession session) async {
    _sessions[_key(session.accountScope, session.localId)] = session;
  }
}

class HiveTrailDraftRepository implements TrailDraftRepository {
  final Box<dynamic> observationBox;
  final Box<dynamic> hikeSessionBox;

  HiveTrailDraftRepository({
    required this.observationBox,
    required this.hikeSessionBox,
  });

  String _key(String accountScope, String localId) => '$accountScope::$localId';

  @override
  Future<void> deleteObservationDraft(
    String accountScope,
    String localId,
  ) {
    return observationBox.delete(_key(accountScope, localId));
  }

  @override
  Future<OfflineObservationDraft?> getObservationDraft(
    String accountScope,
    String localId,
  ) async {
    final dynamic value = observationBox.get(_key(accountScope, localId));
    if (value is! Map) return null;
    return OfflineObservationDraft.fromStorageMap(
      Map<String, dynamic>.from(value),
    );
  }

  @override
  Future<List<OfflineObservationDraft>> listObservationDrafts(
    String accountScope,
  ) async {
    final drafts = observationBox.values
        .whereType<Map>()
        .map(
          (value) => OfflineObservationDraft.fromStorageMap(
            Map<String, dynamic>.from(value),
          ),
        )
        .where((draft) => draft.accountScope == accountScope)
        .toList();
    drafts.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return drafts;
  }

  @override
  Future<void> saveObservationDraft(OfflineObservationDraft draft) {
    return observationBox.put(
      _key(draft.accountScope, draft.localId),
      draft.toStorageMap(),
    );
  }

  @override
  Future<void> deleteHikeSession(
    String accountScope,
    String localId,
  ) {
    return hikeSessionBox.delete(_key(accountScope, localId));
  }

  @override
  Future<OfflineHikeSession?> getActiveHikeSession(
    String accountScope,
  ) async {
    final sessions = await listHikeSessions(accountScope);
    for (final session in sessions) {
      if (session.isActive) return session;
    }
    return null;
  }

  @override
  Future<OfflineHikeSession?> getHikeSession(
    String accountScope,
    String localId,
  ) async {
    final dynamic value = hikeSessionBox.get(_key(accountScope, localId));
    if (value is! Map) return null;
    return OfflineHikeSession.fromStorageMap(
      Map<String, dynamic>.from(value),
    );
  }

  @override
  Future<List<OfflineHikeSession>> listHikeSessions(
    String accountScope,
  ) async {
    final sessions = hikeSessionBox.values
        .whereType<Map>()
        .map(
          (value) => OfflineHikeSession.fromStorageMap(
            Map<String, dynamic>.from(value),
          ),
        )
        .where((session) => session.accountScope == accountScope)
        .toList();
    sessions.sort((left, right) => right.startedAt.compareTo(left.startedAt));
    return sessions;
  }

  @override
  Future<void> saveHikeSession(OfflineHikeSession session) {
    return hikeSessionBox.put(
      _key(session.accountScope, session.localId),
      session.toStorageMap(),
    );
  }
}
