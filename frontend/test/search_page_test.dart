import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/search/search_page.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('search responds immediately and debounces provider requests',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final _SearchHttpClient client = _SearchHttpClient();

    await tester.pumpWidget(await _searchApp(client));

    expect(client.requestCount, 0);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Identify by photo'), findsOneWidget);
    expect(find.textContaining('Type at least 2 characters'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('plant-search-field')),
      'thai chili',
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Searching for'), findsOneWidget);
    expect(client.requestCount, 0);

    await tester.pump(const Duration(milliseconds: 399));
    expect(client.requestCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(client.requestCount, 1);
    expect(client.lastUrl, contains('q=thai+chili'));
    expect(find.textContaining('No catalog result'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('add-custom-plant-result')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard search bypasses debounce and clear resets the screen',
      (tester) async {
    final _SearchHttpClient client = _SearchHttpClient();
    await tester.pumpWidget(await _searchApp(client));

    await tester.enterText(
      find.byKey(const ValueKey('plant-search-field')),
      'thai pepper',
    );
    await tester.pump();
    expect(client.requestCount, 0);

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(client.requestCount, 1);

    await tester.pump(const Duration(milliseconds: 500));
    expect(client.requestCount, 1);

    await tester.tap(find.byKey(const ValueKey('clear-plant-search')));
    await tester.pump();

    expect(find.textContaining('Type at least 2 characters'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(client.requestCount, 1);
    expect(tester.takeException(), isNull);
  });
}

Future<Widget> _searchApp(_SearchHttpClient client) async {
  SharedPreferences.setMockInitialValues({});
  final Environment env = Environment(
    prefs: await SharedPreferences.getInstance(),
    http: client,
    backendVersion: '0.16.1',
    credentials: Credentials(
      username: 'gardener',
      email: 'garden@example.com',
    ),
    notificationDispatcher: [],
    eventTypes: [],
    plants: [],
  );
  return MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SearchPage(env: env)),
  );
}

class _SearchHttpClient extends AppHttpClient {
  int requestCount = 0;
  String? lastUrl;

  _SearchHttpClient() {
    backendUrl = 'http://localhost/api/';
    key = 'test-key';
  }

  @override
  Future<http.Response> get(String url) async {
    requestCount++;
    lastUrl = url;
    return http.Response(
      '[]',
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}
