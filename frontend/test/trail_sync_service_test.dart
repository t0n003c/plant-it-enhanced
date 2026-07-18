import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/observation/offline_hike_session.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';
import 'package:plant_it/observation/trail_draft_repository.dart';
import 'package:plant_it/observation/trail_sync_service.dart';

void main() {
  test('syncs hike, taxon, observation, and photo in dependency order',
      () async {
    final repository = MemoryTrailDraftRepository();
    final client = _FakeTrailHttpClient();
    final DateTime timestamp = DateTime.utc(2026, 7, 18, 14, 30);
    await repository.saveHikeSession(
      OfflineHikeSession(
        localId: 'hike-local-1',
        accountScope: 'nas|hiker',
        name: 'Prairie Loop',
        startedAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await repository.saveObservationDraft(
      _draft(timestamp: timestamp, withTaxon: true),
    );

    final summary = await TrailSyncService(
      http: client,
      repository: repository,
      accountScope: 'nas|hiker',
    ).synchronizePending();

    expect(summary.synchronizedSessions, 1);
    expect(summary.synchronizedDrafts, 1);
    expect(
      await repository.getObservationDraft(
        'nas|hiker',
        'observation-local-1',
      ),
      isNull,
    );
    final session =
        await repository.getHikeSession('nas|hiker', 'hike-local-1');
    expect(session?.serverId, 41);
    expect(session?.syncState, TrailSyncState.synced);
    expect(client.calls, [
      'POST hike-session',
      'POST botanical-info/resolve',
      'POST observation',
      'POST observation/63/image:photo-local-1',
    ]);
    expect(
        client.lastObservationBody?['clientReference'], 'observation-local-1');
    expect(client.lastObservationBody?['hikeSessionId'], 41);
    expect(client.lastObservationBody?['botanicalInfoId'], 52);
  });

  test('keeps partial progress and resumes photo upload after failure',
      () async {
    final repository = MemoryTrailDraftRepository();
    final client = _FakeTrailHttpClient()..failNextPhoto = true;
    final DateTime timestamp = DateTime.utc(2026, 7, 18, 14, 30);
    await repository.saveObservationDraft(_draft(timestamp: timestamp));
    final service = TrailSyncService(
      http: client,
      repository: repository,
      accountScope: 'nas|hiker',
    );

    expect(await service.synchronizeObservation('observation-local-1'), false);
    final failed = await repository.getObservationDraft(
      'nas|hiker',
      'observation-local-1',
    );
    expect(failed?.syncState, TrailSyncState.failed);
    expect(failed?.serverObservationId, 63);
    expect(failed?.lastError, 'Could not upload field photo');
    expect(failed?.photos.single.bytes, [4, 5, 6]);

    expect(await service.synchronizeObservation('observation-local-1'), true);
    expect(
      await repository.getObservationDraft(
        'nas|hiker',
        'observation-local-1',
      ),
      isNull,
    );
    expect(client.calls.where((call) => call == 'POST observation').length, 1);
    expect(
        client.calls.where((call) => call == 'PUT observation/63').length, 1);
    expect(
      client.calls
          .where(
            (call) => call == 'POST observation/63/image:photo-local-1',
          )
          .length,
      2,
    );
  });
}

OfflineObservationDraft _draft({
  required DateTime timestamp,
  bool withTaxon = false,
}) {
  return OfflineObservationDraft(
    localId: 'observation-local-1',
    accountScope: 'nas|hiker',
    createdAt: timestamp,
    updatedAt: timestamp,
    observedAt: timestamp,
    displayName: 'Prairie flower',
    hikeSessionLocalId: withTaxon ? 'hike-local-1' : null,
    selectedTaxon: withTaxon
        ? <String, dynamic>{'scientificName': 'Monarda fistulosa'}
        : null,
    photos: [
      OfflineObservationPhoto(
        localId: 'photo-local-1',
        name: 'flower.jpg',
        contentType: 'image/jpeg',
        organ: 'flower',
        bytes: Uint8List.fromList([4, 5, 6]),
      ),
    ],
  );
}

class _FakeTrailHttpClient extends AppHttpClient {
  final List<String> calls = [];
  Map<String, dynamic>? lastObservationBody;
  bool failNextPhoto = false;

  @override
  Future<http.Response> post(
    String url,
    Map<String, dynamic>? body,
  ) async {
    calls.add('POST $url');
    switch (url) {
      case 'hike-session':
        return _jsonResponse({'id': 41});
      case 'botanical-info/resolve':
        return _jsonResponse({'id': 52});
      case 'observation':
        lastObservationBody = body;
        return _jsonResponse({'id': 63});
      default:
        return _jsonResponse({'message': 'Unexpected POST $url'}, 404);
    }
  }

  @override
  Future<http.Response> put(
    String url,
    Map<String, dynamic>? body,
  ) async {
    calls.add('PUT $url');
    if (url == 'observation/63') {
      lastObservationBody = body;
      return _jsonResponse({'id': 63});
    }
    return _jsonResponse({'message': 'Unexpected PUT $url'}, 404);
  }

  @override
  Future<http.Response> uploadObservationImage(
    XFile image,
    int observationId, {
    String? description,
    String? clientReference,
  }) async {
    calls.add('POST observation/$observationId/image:$clientReference');
    if (failNextPhoto) {
      failNextPhoto = false;
      return _jsonResponse({'message': 'Could not upload field photo'}, 503);
    }
    expect(await image.readAsBytes(), [4, 5, 6]);
    expect(description, 'flower');
    return http.Response('"server-photo-1"', 200);
  }

  http.Response _jsonResponse(Map<String, dynamic> body, [int status = 200]) {
    return http.Response(
      json.encode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  }
}
