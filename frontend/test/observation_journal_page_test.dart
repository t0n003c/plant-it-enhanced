import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/offline_hike_session.dart';
import 'package:plant_it/observation/offline_observation_draft.dart';
import 'package:plant_it/observation/observation_journal_page.dart';
import 'package:plant_it/observation/trail_draft_repository.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('journal keeps offline hike and failed find visible on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = _OfflineTrailHttpClient()
      ..backendUrl = 'http://offline.test/api/';
    final repository = MemoryTrailDraftRepository();
    const String accountScope = 'http://offline.test/api/|hiker';
    final DateTime timestamp = DateTime.utc(2026, 7, 18, 14, 30);
    await repository.saveHikeSession(
      OfflineHikeSession(
        localId: 'hike-local-1',
        accountScope: accountScope,
        name: 'Prairie Loop',
        startedAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await repository.saveObservationDraft(
      OfflineObservationDraft(
        localId: 'observation-local-1',
        accountScope: accountScope,
        createdAt: timestamp,
        updatedAt: timestamp,
        observedAt: timestamp,
        displayName: 'Purple trail flower',
        hikeSessionLocalId: 'hike-local-1',
        hikeSessionName: 'Prairie Loop',
        photos: const [],
      ),
    );
    final env = Environment(
      prefs: prefs,
      http: client,
      backendVersion: 'test',
      credentials: Credentials(
        username: 'hiker',
        email: 'hiker@example.com',
      ),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
      trailDraftRepository: repository,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ObservationJournalPage(env: env),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prairie Loop'), findsOneWidget);
    expect(find.text('Trail dashboard'), findsOneWidget);
    expect(find.text('All finds'), findsOneWidget);
    expect(find.text('Needs ID'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('trail-journal-search')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Finish hike'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Finish hike'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Purple trail flower'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Purple trail flower'), findsOneWidget);
    expect(find.text('1 offline find'), findsOneWidget);
    expect(find.text('Retry'), findsWidgets);
    expect(
      find.textContaining('New finds remain safely on this device'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('identification inbox reuses a saved field photo',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final client = _ReviewTrailHttpClient()
      ..backendUrl = 'https://plants.example.test/api/';
    final env = Environment(
      prefs: prefs,
      http: client,
      backendVersion: 'test',
      credentials: Credentials(
        username: 'hiker',
        email: 'hiker@example.com',
      ),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
      trailDraftRepository: MemoryTrailDraftRepository(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ObservationJournalPage(env: env),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unknown white flower'), findsOneWidget);
    await tester.tap(find.text('Unknown white flower'));
    await tester.pumpAndSettle();
    expect(find.text('Review identification'), findsOneWidget);
    await tester.tap(find.text('Review identification'));
    await tester.pumpAndSettle();

    expect(find.text('Run identification again'), findsOneWidget);
    expect(client.requestedUrls, contains('image/content/field-photo-1'));
    expect(tester.takeException(), isNull);
  });
}

class _OfflineTrailHttpClient extends AppHttpClient {
  @override
  Future<http.Response> get(String url) async {
    return http.Response('{"message":"Offline for test"}', 503);
  }

  @override
  Future<http.Response> post(
    String url,
    Map<String, dynamic>? body,
  ) async {
    return http.Response('{"message":"Offline for test"}', 503);
  }
}

class _ReviewTrailHttpClient extends AppHttpClient {
  final List<String> requestedUrls = [];

  @override
  Future<http.Response> get(String url) async {
    requestedUrls.add(url);
    if (url.startsWith('observation?')) {
      return http.Response(
        '''
        {
          "content": [{
            "id": 42,
            "observedAt": "2026-07-18T14:30:00Z",
            "displayName": "Unknown white flower",
            "trailName": "Oak Ridge",
            "habitat": "Woodland edge",
            "locationPrivacy": "PRIVATE",
            "status": "UNIDENTIFIED",
            "imageIds": ["field-photo-1"]
          }]
        }
        ''',
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (url == 'hike-session') {
      return http.Response(
        '[]',
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (url == 'image/content/field-photo-1') {
      return http.Response.bytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
          'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
        200,
        headers: {'content-type': 'image/png'},
      );
    }
    return http.Response('Not found', 404);
  }
}
