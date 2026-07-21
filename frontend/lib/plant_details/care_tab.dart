import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/care/care_tools_page.dart';
import 'package:plant_it/care/light_check_page.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/health/plant_health_page.dart';

class PlantCareTab extends StatelessWidget {
  final Environment env;
  final PlantDTO plant;
  final SpeciesDTO? species;

  const PlantCareTab({
    super.key,
    required this.env,
    required this.plant,
    this.species,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.careToolsIntro,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          CareToolCard(
            key: const ValueKey<String>('plant-care-health'),
            icon: Icons.health_and_safety_outlined,
            title: localizations.plantHealthCheck,
            description: localizations.plantHealthCheckDescription,
            actionLabel: localizations.startHealthCheck,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlantHealthPage(
                  env: env,
                  initialPlant: plant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CareToolCard(
            key: const ValueKey<String>('plant-care-light'),
            icon: Icons.wb_sunny_outlined,
            title: localizations.lightPlacementCheck,
            description: localizations.lightPlacementCheckDescription,
            actionLabel: localizations.checkPlantLight,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LightCheckPage(
                  env: env,
                  initialPlant: plant,
                  initialSpecies: species,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(localizations.careToolsPrivacy)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
