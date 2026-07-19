import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/homepage/plant_list.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('collection search always filters the complete plant list',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final Environment env = await _environment([
      _plant(1, 'Kitchen mint', 'Mentha spicata'),
      _plant(2, 'Big Monstera', 'Monstera deliciosa'),
    ]);

    await tester.pumpWidget(_app(PlantList(env: env)));

    final Finder search = find.byType(TextField);
    await tester.enterText(search, 'mint');
    await tester.pump(const Duration(milliseconds: 251));
    expect(find.text('No plants match this search'), findsNothing);

    // This used to filter the previous "mint" result instead of starting from
    // the complete collection, leaving Monstera incorrectly hidden.
    await tester.enterText(search, 'mon');
    await tester.pump(const Duration(milliseconds: 251));
    expect(find.text('No plants match this search'), findsNothing);
    expect(find.byType(PlantCard), findsOneWidget);

    await tester.enterText(search, 'nothing-here');
    await tester.pump(const Duration(milliseconds: 251));
    expect(find.text('No plants match this search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty collection explains how to add the first plant',
      (tester) async {
    final Environment env = await _environment([]);
    await tester.pumpWidget(_app(PlantList(env: env)));

    expect(find.text('Your green-friend collection is empty'), findsOneWidget);
    expect(find.textContaining('Use Search'), findsOneWidget);
  });
}

PlantDTO _plant(int id, String name, String species) {
  return PlantDTO(
    id: id,
    species: species,
    avatarImageId: 'missing-$id',
    avatarMode: 'NONE',
    info: PlantInfoDTO(personalName: name),
  );
}

Future<Environment> _environment(List<PlantDTO> plants) async {
  SharedPreferences.setMockInitialValues({});
  final AppHttpClient http = AppHttpClient()
    ..backendUrl = 'http://localhost/api/'
    ..key = 'test-key';
  return Environment(
    prefs: await SharedPreferences.getInstance(),
    http: http,
    backendVersion: 'test',
    credentials: Credentials(
      username: 'gardener',
      email: 'garden@example.com',
    ),
    notificationDispatcher: [],
    eventTypes: [],
    plants: plants,
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
