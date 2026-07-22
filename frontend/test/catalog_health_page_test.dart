import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/more/catalog_health_page.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('catalog health is readable on a narrow mobile screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final Environment env = Environment(
      prefs: await SharedPreferences.getInstance(),
      http: _CatalogHealthHttpClient(),
      backendVersion: '0.17.1',
      credentials:
          Credentials(username: 'gardener', email: 'garden@example.com'),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CatalogHealthPage(env: env),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The reviewed catalog is healthy'), findsOneWidget);
    expect(find.text('2000'), findsOneWidget);
    expect(find.text('Cultivated plants'), findsOneWidget);
    expect(find.byKey(const ValueKey('copy-catalog-health-report')),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.textContaining('No unresolved search'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Search discovery'), findsOneWidget);
    expect(find.textContaining('No unresolved search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _CatalogHealthHttpClient extends AppHttpClient {
  @override
  Future<http.Response> get(String url) async {
    return http.Response(
      '''
      {
        "schemaVersion": 1,
        "healthy": true,
        "totals": {
          "reviewedEntries": 176,
          "reviewedQueries": 853,
          "searchableEntries": 2000,
          "searchableQueries": 4514,
          "curatedCareProfiles": 86,
          "liveCanaries": 14,
          "contactHazards": 11
        },
        "tiers": [
          {
            "name": "CURATED_CULTIVATED",
            "entries": 86,
            "reviewedQueries": 453,
            "imageRequiredEntries": 86,
            "careRequiredEntries": 86,
            "careCompleteEntries": 86,
            "searchCoveragePercent": 100,
            "careCoveragePercent": 100
          },
          {
            "name": "NORTH_AMERICAN_TRAIL",
            "entries": 90,
            "reviewedQueries": 400,
            "imageRequiredEntries": 90,
            "careRequiredEntries": 0,
            "careCompleteEntries": 0,
            "searchCoveragePercent": 100,
            "careCoveragePercent": 100
          },
          {
            "name": "SEARCH_DISCOVERY",
            "entries": 1820,
            "reviewedQueries": 3640,
            "imageRequiredEntries": 0,
            "careRequiredEntries": 0,
            "careCompleteEntries": 0,
            "searchCoveragePercent": 100,
            "careCoveragePercent": 100
          }
        ],
        "activeGapCount": 0,
        "activeGapCounts": {},
        "recentGaps": [],
        "policyIssues": []
      }
      ''',
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
