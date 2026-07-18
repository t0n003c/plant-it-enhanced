import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/observation/offline_hike_session.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';
import 'package:plant_it/observation/trail_draft_repository.dart';

class TrailSyncSummary {
  final int synchronizedDrafts;
  final int failedDrafts;
  final int synchronizedSessions;
  final int failedSessions;

  const TrailSyncSummary({
    required this.synchronizedDrafts,
    required this.failedDrafts,
    required this.synchronizedSessions,
    required this.failedSessions,
  });
}

class TrailSyncService {
  final AppHttpClient http;
  final TrailDraftRepository repository;
  final String accountScope;

  TrailSyncService({
    required this.http,
    required this.repository,
    required this.accountScope,
  });

  Future<TrailSyncSummary> synchronizePending() async {
    int synchronizedSessions = 0;
    int failedSessions = 0;
    final sessions = await repository.listHikeSessions(accountScope);
    for (final session in sessions.where(
      (session) => session.syncState != TrailSyncState.synced,
    )) {
      if (await synchronizeHikeSession(session.localId)) {
        synchronizedSessions++;
      } else {
        failedSessions++;
      }
    }

    int synchronizedDrafts = 0;
    int failedDrafts = 0;
    final drafts = await repository.listObservationDrafts(accountScope);
    for (final draft in drafts) {
      if (await synchronizeObservation(draft.localId)) {
        synchronizedDrafts++;
      } else {
        failedDrafts++;
      }
    }
    return TrailSyncSummary(
      synchronizedDrafts: synchronizedDrafts,
      failedDrafts: failedDrafts,
      synchronizedSessions: synchronizedSessions,
      failedSessions: failedSessions,
    );
  }

  Future<bool> synchronizeHikeSession(String localId) async {
    final OfflineHikeSession? session =
        await repository.getHikeSession(accountScope, localId);
    if (session == null) return true;
    if (session.syncState == TrailSyncState.synced) return true;
    session.syncState = TrailSyncState.syncing;
    session.lastError = null;
    session.updatedAt = DateTime.now();
    await repository.saveHikeSession(session);
    try {
      final response = session.serverId == null
          ? await http.post('hike-session', session.toServerMap())
          : await http.put(
              'hike-session/${session.serverId}',
              session.toServerMap(),
            );
      if (response.statusCode != 200) {
        throw TrailSyncException(
          _responseMessage(response.bodyBytes, 'Could not sync hike'),
        );
      }
      final body = json.decode(utf8.decode(response.bodyBytes));
      session.serverId = (body['id'] as num).toInt();
      session.syncState = TrailSyncState.synced;
      session.lastError = null;
      session.updatedAt = DateTime.now();
      await repository.saveHikeSession(session);
      return true;
    } catch (error) {
      session.syncState = TrailSyncState.failed;
      session.lastError = _errorMessage(error);
      session.retryCount++;
      session.updatedAt = DateTime.now();
      await repository.saveHikeSession(session);
      return false;
    }
  }

  Future<bool> synchronizeObservation(String localId) async {
    final OfflineObservationDraft? draft =
        await repository.getObservationDraft(accountScope, localId);
    if (draft == null) return true;
    draft.syncState = TrailSyncState.syncing;
    draft.lastError = null;
    draft.lastAttemptAt = DateTime.now();
    draft.updatedAt = DateTime.now();
    await repository.saveObservationDraft(draft);
    try {
      await _resolveHikeSession(draft);
      await _resolveTaxon(draft);
      await _createObservation(draft);
      await _uploadPhotos(draft);
      await repository.deleteObservationDraft(accountScope, draft.localId);
      return true;
    } catch (error) {
      draft.syncState = TrailSyncState.failed;
      draft.lastError = _errorMessage(error);
      draft.retryCount++;
      draft.updatedAt = DateTime.now();
      await repository.saveObservationDraft(draft);
      return false;
    }
  }

  Future<void> _resolveHikeSession(OfflineObservationDraft draft) async {
    if (draft.hikeSessionId != null || draft.hikeSessionLocalId == null) {
      return;
    }
    final OfflineHikeSession? session = await repository.getHikeSession(
      accountScope,
      draft.hikeSessionLocalId!,
    );
    if (session == null) return;
    if (session.serverId == null ||
        session.syncState != TrailSyncState.synced) {
      final bool synchronized = await synchronizeHikeSession(session.localId);
      if (!synchronized) {
        final OfflineHikeSession? failed = await repository.getHikeSession(
          accountScope,
          session.localId,
        );
        throw TrailSyncException(
          failed?.lastError ?? 'Could not sync the hike session',
        );
      }
    }
    final OfflineHikeSession? synchronized = await repository.getHikeSession(
      accountScope,
      session.localId,
    );
    draft.hikeSessionId = synchronized?.serverId;
    await repository.saveObservationDraft(draft);
  }

  Future<void> _resolveTaxon(OfflineObservationDraft draft) async {
    if (draft.botanicalInfoId != null || draft.selectedTaxon == null) return;
    final response =
        await http.post('botanical-info/resolve', draft.selectedTaxon!);
    if (response.statusCode != 200) {
      throw TrailSyncException(
        _responseMessage(response.bodyBytes, 'Could not save identification'),
      );
    }
    final dynamic body = json.decode(utf8.decode(response.bodyBytes));
    draft.botanicalInfoId = (body['id'] as num).toInt();
    await repository.saveObservationDraft(draft);
  }

  Future<void> _createObservation(OfflineObservationDraft draft) async {
    final response = draft.serverObservationId == null
        ? await http.post('observation', draft.toObservationMap())
        : await http.put(
            'observation/${draft.serverObservationId}',
            draft.toObservationMap(),
          );
    if (response.statusCode != 200) {
      throw TrailSyncException(
        _responseMessage(response.bodyBytes, 'Could not save observation'),
      );
    }
    final dynamic body = json.decode(utf8.decode(response.bodyBytes));
    draft.serverObservationId = (body['id'] as num).toInt();
    await repository.saveObservationDraft(draft);
  }

  Future<void> _uploadPhotos(OfflineObservationDraft draft) async {
    for (final photo in draft.photos) {
      if (photo.serverImageId != null) continue;
      final response = await http.uploadObservationImage(
        XFile.fromData(
          photo.bytes,
          name: photo.name,
          mimeType: photo.contentType,
        ),
        draft.serverObservationId!,
        description: photo.organ,
        clientReference: photo.localId,
      );
      if (response.statusCode != 200) {
        throw TrailSyncException(
          _responseMessage(response.bodyBytes, 'Could not upload field photo'),
        );
      }
      photo.serverImageId = response.body.replaceAll('"', '').trim();
      await repository.saveObservationDraft(draft);
    }
  }

  String _responseMessage(List<int> bytes, String fallback) {
    try {
      final dynamic body = json.decode(utf8.decode(bytes));
      if (body is Map && body['message'] != null) {
        return body['message'].toString();
      }
    } catch (_) {
      // A non-JSON upstream response is represented by the stable fallback.
    }
    return fallback;
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('TrailSyncException: ', '');
  }
}

class TrailSyncException implements Exception {
  final String message;

  const TrailSyncException(this.message);

  @override
  String toString() => 'TrailSyncException: $message';
}
