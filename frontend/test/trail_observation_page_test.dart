import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/add_observation_page.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('trail capture has readable mobile photo and save actions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final env = Environment(
      prefs: prefs,
      http: AppHttpClient(),
      backendVersion: 'test',
      credentials: Credentials(username: 'hiker', email: 'hiker@example.com'),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddObservationPage(env: env),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start with a plant photo'), findsNWidgets(2));
    expect(find.text('Leave what you find'), findsOneWidget);
    expect(find.text('Save trail observation'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(
            const ValueKey('save-trail-observation-button'),
          ))
          .height,
      greaterThanOrEqualTo(58),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('trail-photo-button'))).height,
      greaterThanOrEqualTo(58),
    );
  });
}
