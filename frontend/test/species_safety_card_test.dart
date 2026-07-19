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
    expect(find.text('People'), findsOneWidget);
    expect(find.text('Cats'), findsOneWidget);
    expect(find.text('Dogs'), findsOneWidget);
    expect(find.text('Highly toxic'), findsOneWidget);
    expect(find.text('No known toxicity'), findsOneWidget);
    expect(find.text('Possible exposure?'), findsOneWidget);
    expect(find.text('ASPCA Animal Poison Control'), findsOneWidget);
    expect(find.textContaining('not an edibility guide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an honest unknown state for an unreviewed plant',
      (tester) async {
    await tester.pumpWidget(_detailsApp(_unknownPlant()));
    await tester.scrollUntilVisible(
      find.text('Safety at home'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Unknown'), findsNWidgets(3));
    expect(find.textContaining('No reviewed safety profile'), findsOneWidget);
    expect(find.text('Possible exposure?'), findsNothing);
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
  );
}

SpeciesDTO _unknownPlant() {
  return SpeciesDTO(
    scientificName: 'Example plant',
    care: SpeciesCareInfoDTO.fromJson(<String, dynamic>{}),
    creator: 'USER',
  );
}
