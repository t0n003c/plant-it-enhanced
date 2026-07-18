import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:plant_it/observation/offline_hike_session.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';
import 'package:plant_it/observation/trail_draft_repository.dart';

void main() {
  test('Hive repository keeps offline photos and isolates accounts', () async {
    final Directory storage =
        await Directory.systemTemp.createTemp('plantit-trail-drafts-');
    Hive.init(storage.path);
    final Box<dynamic> observationBox =
        await Hive.openBox<dynamic>('observations');
    final Box<dynamic> hikeBox = await Hive.openBox<dynamic>('hikes');
    final repository = HiveTrailDraftRepository(
      observationBox: observationBox,
      hikeSessionBox: hikeBox,
    );
    addTearDown(() async {
      await Hive.close();
      await storage.delete(recursive: true);
    });

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
      OfflineObservationDraft(
        localId: 'observation-local-1',
        accountScope: 'nas|hiker',
        createdAt: timestamp,
        updatedAt: timestamp,
        observedAt: timestamp,
        hikeSessionLocalId: 'hike-local-1',
        displayName: 'Purple flower',
        photos: [
          OfflineObservationPhoto(
            localId: 'photo-local-1',
            name: 'flower.jpg',
            contentType: 'image/jpeg',
            organ: 'flower',
            bytes: Uint8List.fromList([1, 2, 3, 255]),
          ),
        ],
      ),
    );

    final OfflineObservationDraft? restored = await repository
        .getObservationDraft('nas|hiker', 'observation-local-1');
    expect(restored?.displayName, 'Purple flower');
    expect(restored?.photos.single.bytes, [1, 2, 3, 255]);
    expect(
      (await repository.getActiveHikeSession('nas|hiker'))?.name,
      'Prairie Loop',
    );
    expect(await repository.listObservationDrafts('other|hiker'), isEmpty);
  });

  test('interrupted sync is restored as a retryable failure', () {
    final DateTime timestamp = DateTime.utc(2026, 7, 18, 14, 30);
    final draft = OfflineObservationDraft(
      localId: 'observation-local-2',
      accountScope: 'nas|hiker',
      createdAt: timestamp,
      updatedAt: timestamp,
      observedAt: timestamp,
      photos: const [],
      syncState: TrailSyncState.syncing,
    );

    final restored = OfflineObservationDraft.fromStorageMap(
      draft.toStorageMap(),
    );

    expect(restored.syncState, TrailSyncState.failed);
    expect(restored.lastError, contains('interrupted'));
  });
}
