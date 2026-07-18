import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/observation/identification_candidate_card.dart';
import 'package:plant_it/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows visual score, evidence, status, and safety on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final Environment env = Environment(
      prefs: prefs,
      http: AppHttpClient(),
      backendVersion: 'test',
      credentials: Credentials(username: 'hiker', email: 'hiker@example.test'),
      notificationDispatcher: [],
      eventTypes: [],
      plants: [],
    );
    final SpeciesDTO candidate = SpeciesDTO(
      scientificName: 'Toxicodendron radicans',
      preferredCommonName: 'Eastern poison ivy',
      family: 'Anacardiaceae',
      care: SpeciesCareInfoDTO(),
      creator: 'PLANTNET',
      identificationConfidence: .84,
      contextualIdentificationScore: .96,
      establishmentMeans: 'native',
      establishmentPlace: 'United States',
      catalogTags: const ['NORTH_AMERICAN_TRAIL', 'CONTACT_HAZARD'],
      identificationEvidence: const [
        IdentificationEvidenceDTO(
          code: 'REGIONAL_FLORA',
          adjustment: .02,
          source: 'Pl@ntNet',
          detail: 'Northern America',
        ),
        IdentificationEvidenceDTO(
          code: 'NEARBY_SEASONAL_OCCURRENCES',
          adjustment: .10,
          source: 'iNaturalist',
          observationCount: 42,
          detail: '6,7,8',
        ),
      ],
    );
    SpeciesDTO? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: IdentificationCandidateCard(
              candidate: candidate,
              env: env,
              rank: 1,
              selected: false,
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Candidate 1'), findsOneWidget);
    expect(find.text('Eastern poison ivy'), findsOneWidget);
    expect(find.text('Photo 84%'), findsOneWidget);
    expect(find.text('Context rank 96%'), findsOneWidget);
    expect(find.text('Native in United States'), findsOneWidget);
    expect(
      find.textContaining('42 nearby research-grade observations'),
      findsOneWidget,
    );
    expect(find.textContaining('Do not touch it'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'identification-candidate-Toxicodendron radicans',
        ),
      ),
    );
    expect(selected, same(candidate));
    expect(tester.takeException(), isNull);
  });
}
