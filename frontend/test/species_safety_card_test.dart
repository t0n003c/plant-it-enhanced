import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/plant_details/species_tab.dart';
import 'package:plant_it/theme.dart';

void main() {
  testWidgets(
      'shows attributable lily safety clearly on a narrow mobile screen',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_detailsApp(_lily()));
    await tester.scrollUntilVisible(
      find.text('Safety at home'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Safety at home'), findsOneWidget);
    expect(find.text('Cats'), findsOneWidget);
    expect(find.text('Dogs'), findsOneWidget);
    expect(find.text('Highly toxic'), findsOneWidget);
    expect(find.text('No known toxicity'), findsOneWidget);
    expect(find.text('Possible exposure?'), findsOneWidget);
    expect(find.text('ASPCA Animal Poison Control'), findsNothing);
    expect(find.textContaining('not an edibility guide'), findsNothing);
    expect(find.textContaining('Profile matched to'), findsNothing);
    expect(find.textContaining('Notes matched to'), findsNothing);
    expect(find.text('Food and medicine notes'), findsOneWidget);
    expect(find.text('For people'), findsOneWidget);
    expect(find.text('Food · Edible fruit'), findsOneWidget);
    expect(find.textContaining('Nutrition information'), findsOneWidget);

    await tester.tap(find.byKey(const Key('safetyReviewedSources')));
    await tester.pumpAndSettle();
    expect(find.text('ASPCA Animal Poison Control'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('benefitReviewedSources')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('benefitReviewedSources')));
    await tester.pumpAndSettle();
    expect(find.text('Example source'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides empty safety and benefit sections for an unreviewed plant',
      (tester) async {
    await tester.pumpWidget(_detailsApp(_unknownPlant()));

    expect(find.text('Safety at home'), findsNothing);
    expect(find.text('Food and medicine notes'), findsNothing);
    expect(find.text('Unknown'), findsNothing);
    expect(find.text('Possible exposure?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps pet caution when there is no reviewed pet benefit',
      (tester) async {
    await tester.pumpWidget(_detailsApp(_thaiChiliWithoutPetBenefit()));
    await tester.scrollUntilVisible(
      find.text('Food and medicine notes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('For pets'), findsOneWidget);
    expect(
      find.text(
        'Avoid spicy, seasoned, salted, or prepared human foods. Contact a veterinarian for feeding or exposure questions.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('There is no reviewed pet-health benefit'),
      findsNothing,
    );
    expect(find.text('No veterinary treatment claim'), findsNothing);
    expect(find.text('No treatment claim'), findsNothing);
    expect(find.text('Medicine'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows additional available care metrics', (tester) async {
    await tester.pumpWidget(
      _detailsApp(
        SpeciesDTO(
          scientificName: 'Example plant',
          care: SpeciesCareInfoDTO(
            humidity: 7,
            minTemp: 12,
            maxTemp: 28,
            phMin: 5.5,
            phMax: 6.5,
          ),
          creator: 'TRUSTED_NAME_INDEX',
        ),
      ),
    );

    expect(find.text('Humidity'), findsOneWidget);
    expect(find.text('7 out of 10'), findsOneWidget);
    expect(
        find.text('Minimum temperature / Maximum temperature'), findsOneWidget);
    expect(find.text('12 °C – 28 °C'), findsOneWidget);
    expect(find.text('Minimum ph / Maximum ph'), findsOneWidget);
    expect(find.text('5.5 – 6.5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps care cards focused on actionable guidance',
      (tester) async {
    await tester.pumpWidget(
      _detailsApp(
        SpeciesDTO(
          scientificName: 'Example plant',
          care: SpeciesCareInfoDTO(
            lightRequirement: 'HIGH',
            waterRequirement: 'MODERATE',
          ),
          creator: 'TRUSTED_NAME_INDEX',
        ),
      ),
    );

    expect(find.text('Sunlight · High'), findsOneWidget);
    expect(find.text('watering · Moderate'), findsOneWidget);
    expect(find.textContaining('General guidance only'), findsNothing);
    expect(find.textContaining('CURATED_CATALOG'), findsNothing);
    expect(find.textContaining('88%'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _detailsApp(SpeciesDTO species) {
  return MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SpeciesDetailsTab(species: species, isLoading: false),
    ),
  );
}

SpeciesDTO _lily() {
  return SpeciesDTO(
    scientificName: 'Lilium',
    family: 'Liliaceae',
    genus: 'Lilium',
    species: 'Lilium',
    care: SpeciesCareInfoDTO.fromJson(<String, dynamic>{}),
    creator: 'TRUSTED_NAME_INDEX',
    safety: PlantSafetyInfoDTO(
      humanStatus: 'UNKNOWN',
      catStatus: 'HIGHLY_TOXIC',
      dogStatus: 'NON_TOXIC',
      summary: 'True lilies are an emergency-level hazard for cats.',
      hazardousParts: const ['All plant parts', 'Pollen', 'Vase water'],
      sources: const [
        PlantSafetySourceDTO(
          name: 'ASPCA Animal Poison Control',
          url: 'https://www.aspca.org/example',
        ),
      ],
      lastVerifiedAt: DateTime.utc(2026, 7, 18),
      reviewed: true,
      matchedTaxon: 'Lilium',
    ),
    benefits: const PlantBenefitInfoDTO(
      entries: [
        PlantBenefitEntryDTO(
          audience: 'HUMAN',
          category: 'FOOD',
          title: 'Edible fruit',
          summary: 'Nutrition information only.',
          caution: 'Not medical advice.',
        ),
      ],
      sources: [
        PlantBenefitSourceDTO(
          name: 'Example source',
          url: 'https://example.com/benefits',
        ),
      ],
      reviewed: true,
      matchedTaxon: 'Example taxon',
    ),
  );
}

SpeciesDTO _thaiChiliWithoutPetBenefit() {
  return SpeciesDTO(
    scientificName: 'Capsicum annuum',
    preferredCommonName: 'Thai chili',
    care: SpeciesCareInfoDTO.fromJson(<String, dynamic>{}),
    creator: 'TRUSTED_NAME_INDEX',
    benefits: const PlantBenefitInfoDTO(
      entries: [
        PlantBenefitEntryDTO(
          audience: 'PET',
          category: 'FOOD',
          title: 'Not a pet dietary supplement',
          summary:
              'There is no reviewed pet-health benefit for feeding bell or hot peppers in this catalog.',
          caution:
              'Avoid spicy, seasoned, salted, or prepared human foods. Contact a veterinarian for feeding or exposure questions.',
        ),
        PlantBenefitEntryDTO(
          audience: 'PET',
          category: 'MEDICINE',
          title: 'No veterinary treatment claim',
          summary:
              'This catalog does not recommend Capsicum as a veterinary medicine or treatment.',
          caution: 'Do not use peppers or pepper extracts to treat a pet.',
        ),
        PlantBenefitEntryDTO(
          audience: 'HUMAN',
          category: 'MEDICINE',
          title: 'No treatment claim',
          summary:
              'This catalog does not recommend Capsicum as medicine or as a treatment for any condition.',
          caution: 'Do not replace medical care or prescribed treatment.',
        ),
      ],
      reviewed: true,
    ),
  );
}

SpeciesDTO _unknownPlant() {
  return SpeciesDTO(
    scientificName: 'Example plant',
    care: SpeciesCareInfoDTO.fromJson(<String, dynamic>{}),
    creator: 'USER',
  );
}
