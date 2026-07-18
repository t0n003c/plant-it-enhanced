import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/dto/observation_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/observation_review_service.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('turns a saved observation and its photos into a safe review draft',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = _SavedPhotoHttpClient()
      ..backendUrl = 'https://plants.example.test/api/';
    final Environment env = Environment(
      prefs: prefs,
      http: client,
      backendVersion: 'test',
      credentials: Credentials(
        username: 'Hiker',
        email: 'hiker@example.test',
      ),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
    );
    final DateTime observedAt = DateTime.utc(2026, 7, 18, 14, 30);
    final ObservationDTO observation = ObservationDTO(
      id: 42,
      botanicalInfoId: 12,
      observedAt: observedAt,
      displayName: 'Unknown woodland flower',
      trailName: 'Oak Ridge',
      habitat: 'Woodland edge',
      latitude: 41.8,
      longitude: -87.6,
      elevationMeters: 190,
      imageIds: const ['jpeg-photo', 'png-photo'],
    );

    final OfflineObservationDraft draft =
        await ObservationReviewService(env).createDraft(observation);

    expect(draft.localId, 'server-observation-42');
    expect(draft.serverObservationId, 42);
    expect(draft.botanicalInfoId, 12);
    expect(draft.accountScope, 'https://plants.example.test/api/|hiker');
    expect(draft.observedAt, observedAt);
    expect(draft.habitat, 'Woodland edge');
    expect(draft.syncState, TrailSyncState.pending);
    expect(draft.photos, hasLength(2));
    expect(draft.photos.first.serverImageId, 'jpeg-photo');
    expect(draft.photos.first.contentType, 'image/jpeg');
    expect(draft.photos.first.bytes, Uint8List.fromList([1, 2, 3]));
    expect(draft.photos.last.serverImageId, 'png-photo');
    expect(draft.photos.last.name, 'png-photo.png');
    expect(client.requestedUrls, [
      'image/content/jpeg-photo',
      'image/content/png-photo',
    ]);
  });

  test('rejects a review that is not tied to a saved observation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final Environment env = Environment(
      prefs: prefs,
      http: _SavedPhotoHttpClient(),
      backendVersion: 'test',
      credentials: Credentials(username: 'hiker', email: 'hiker@example.test'),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
    );

    expect(
      () => ObservationReviewService(env).createDraft(
        ObservationDTO(observedAt: DateTime.utc(2026, 7, 18)),
      ),
      throwsArgumentError,
    );
  });
}

class _SavedPhotoHttpClient extends AppHttpClient {
  final List<String> requestedUrls = [];

  @override
  Future<http.Response> get(String url) async {
    requestedUrls.add(url);
    if (url.endsWith('png-photo')) {
      return http.Response.bytes(
        [4, 5, 6],
        200,
        headers: {'content-type': 'image/png'},
      );
    }
    return http.Response.bytes(
      [1, 2, 3],
      200,
      headers: {'content-type': 'image/jpeg; charset=binary'},
    );
  }
}
