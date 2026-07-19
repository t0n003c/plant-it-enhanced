import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/care/care_tools_page.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/health/plant_health_page.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('care hub exposes both private guided tools on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final Environment env = Environment(
      prefs: await SharedPreferences.getInstance(),
      http: AppHttpClient(),
      backendVersion: 'test',
      credentials: Credentials(
        username: 'gardener',
        email: 'garden@example.com',
      ),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CareToolsPage(env: env),
      ),
    );

    expect(find.text('Plant health check'), findsOneWidget);
    expect(find.text('Light placement check'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('not uploaded'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('not uploaded'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Start health check'));
    await tester.pumpAndSettle();

    expect(find.byType(PlantHealthPage), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Take a plant photo'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
