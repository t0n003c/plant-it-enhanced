import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/search/search_result.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('photo-first result exposes identity, details, and safety',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final Environment env = await _environment();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SearchResultCard(
                species: _lily(),
                env: env,
                result: const [],
                identificationImage: XFile.fromData(_pixel),
                updateSpeciesLocally: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lily'), findsOneWidget);
    expect(find.text('Lilium'), findsOneWidget);
    expect(find.text('Safety at home: Highly toxic'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-result-photo-frame')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not summarize partially unknown safety as non-toxic',
      (tester) async {
    final Environment env = await _environment();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SearchResultCard(
              species: _partiallyUnknownPlant(),
              env: env,
              result: const [],
              identificationImage: XFile.fromData(_pixel),
              updateSpeciesLocally: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Safety at home: No known toxicity'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<Environment> _environment() async {
  SharedPreferences.setMockInitialValues({});
  final AppHttpClient http = AppHttpClient()
    ..backendUrl = 'http://localhost/api/'
    ..key = 'test-key';
  return Environment(
    prefs: await SharedPreferences.getInstance(),
    http: http,
    backendVersion: '0.16.3',
    credentials: Credentials(
      username: 'gardener',
      email: 'garden@example.com',
    ),
    notificationDispatcher: const [],
    eventTypes: const [],
    plants: const [],
  );
}

SpeciesDTO _lily() {
  return SpeciesDTO(
    scientificName: 'Lilium',
    preferredCommonName: 'Lily',
    family: 'Liliaceae',
    care: SpeciesCareInfoDTO.fromJson(<String, dynamic>{}),
    creator: 'TRUSTED_NAME_INDEX',
    searchMatchReason: 'EXACT_COMMON_NAME',
    searchMatchConfidence: 1,
    safety: const PlantSafetyInfoDTO(
      humanStatus: 'UNKNOWN',
      catStatus: 'HIGHLY_TOXIC',
      dogStatus: 'NON_TOXIC',
      summary: 'True lilies are an emergency-level hazard for cats.',
      reviewed: true,
      hazardousParts: [],
      sources: [],
    ),
  );
}

SpeciesDTO _partiallyUnknownPlant() {
  return SpeciesDTO(
    scientificName: 'Example plant',
    care: SpeciesCareInfoDTO.fromJson(<String, dynamic>{}),
    creator: 'TRUSTED_NAME_INDEX',
    safety: const PlantSafetyInfoDTO(
      humanStatus: 'UNKNOWN',
      catStatus: 'NON_TOXIC',
      dogStatus: 'NON_TOXIC',
      reviewed: true,
    ),
  );
}

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
