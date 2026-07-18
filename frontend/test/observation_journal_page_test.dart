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

    expect(find.text('Prairie Loop'), findsNWidgets(2));
    expect(find.text('Purple trail flower'), findsOneWidget);
    expect(find.text('1 offline find'), findsOneWidget);
    expect(find.text('Retry sync'), findsOneWidget);
    expect(find.text('Retry'), findsNWidgets(2));
    expect(find.text('Finish hike'), findsOneWidget);
    expect(
      find.textContaining('New finds remain safely on this device'),
      findsOneWidget,
    );
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
