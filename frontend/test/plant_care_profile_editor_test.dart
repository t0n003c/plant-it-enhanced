import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/plant_care_profile_editor.dart';
import 'package:plant_it/theme.dart';

void main() {
  testWidgets('reusable editor includes every personalized care field',
      (tester) async {
    final PlantInfoDTO info = PlantInfoDTO(
      growingEnvironment: 'INDOOR',
      lightExposure: 'MEDIUM',
      windowDirection: 'E',
      potDiameterCm: 18,
      potMaterial: 'TERRACOTTA',
      hasDrainage: true,
      soilType: 'Aroid mix',
      lastWateredAt: '2026-07-18T00:00:00.000',
      lastRepottedAt: '2026-06-01T00:00:00.000',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlantCareProfileEditor(
              info: info,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Personalized care profile'), findsOneWidget);
    expect(find.text('Growing environment'), findsOneWidget);
    expect(find.text('Observed light'), findsOneWidget);
    expect(find.text('Nearest window direction'), findsOneWidget);
    expect(find.text('Pot diameter (cm)'), findsOneWidget);
    expect(find.text('Pot material'), findsOneWidget);
    expect(find.text('Container has a drainage hole'), findsOneWidget);
    expect(find.text('Soil or growing medium'), findsOneWidget);
    expect(find.text('Last watered'), findsOneWidget);
    expect(find.text('Last repotted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
