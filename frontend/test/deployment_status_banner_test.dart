import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/deployment_build_info.dart';
import 'package:plant_it/deployment_status_banner.dart';
import 'package:plant_it/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localizations_injector.dart';

void main() {
  testWidgets('shows an accessible stale-build notice on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final Environment env = Environment(
      prefs: await SharedPreferences.getInstance(),
      http: AppHttpClient()..backendUrl = 'https://plant.example.com/api/',
      backendVersion: '0.16.0',
      credentials: Credentials(username: 'tester', email: 'test@example.com'),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
    );

    await tester.pumpWidget(
      LocalizationsInjector(
        navigatorObserver: NavigatorObserver(),
        child: DeploymentStatusBanner(
          env: env,
          interfaceRevision: 'aaaaaaaaaaaaaaaa',
          loadBuildInfo: () async => const DeploymentBuildInfo(
            version: '0.16.0',
            revision: 'bbbbbbbbbbbbbbbb',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A newer server build is running'), findsOneWidget);
    expect(find.text('Refresh app safely'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
