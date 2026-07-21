import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/care/light_exposure_assessment.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/toast/toast_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class LightCheckPage extends StatefulWidget {
  final Environment env;
  final PlantDTO? initialPlant;
  final SpeciesDTO? initialSpecies;

  const LightCheckPage({
    super.key,
    required this.env,
    this.initialPlant,
    this.initialSpecies,
  });

  @override
  State<LightCheckPage> createState() => _LightCheckPageState();
}

class _LightCheckPageState extends State<LightCheckPage> {
  PlantDTO? _plant;
  SpeciesDTO? _species;
  bool _loadingSpecies = false;
  bool _saving = false;
  NaturalLightDuration _directLight = NaturalLightDuration.none;
  WindowDistance _distance = WindowDistance.middle;
  WindowObstruction _obstruction = WindowObstruction.filtered;
  LightExposureResult? _result;

  @override
  void initState() {
    super.initState();
    _plant = widget.initialPlant;
    _species = widget.initialSpecies;
    if (_species == null && _plant?.speciesId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadSpecies(_plant!),
      );
    }
  }

  Future<void> _loadSpecies(PlantDTO plant) async {
    if (plant.speciesId == null) return;
    setState(() => _loadingSpecies = true);
    try {
      final response =
          await widget.env.http.get('botanical-info/${plant.speciesId}');
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (!mounted || _plant?.id != plant.id) return;
      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        setState(() => _species = SpeciesDTO.fromJson(body));
      }
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
    } finally {
      if (mounted && _plant?.id == plant.id) {
        setState(() => _loadingSpecies = false);
      }
    }
  }

  void _selectPlant(PlantDTO? plant) {
    setState(() {
      _plant = plant;
      _species = null;
      _result = null;
    });
    if (plant != null) _loadSpecies(plant);
  }

  void _checkPlacement() {
    setState(() {
      _result = LightExposureAssessment.evaluate(
        LightExposureInput(
          directLight: _directLight,
          distance: _distance,
          obstruction: _obstruction,
        ),
        requiredLevel: _species?.care.lightRequirement,
      );
    });
  }

  Future<void> _saveObservedLight() async {
    final PlantDTO? plant = _plant;
    final LightExposureResult? result = _result;
    if (plant?.id == null || result == null || _saving) return;
    final PlantDTO updated = PlantDTO.fromJson(plant!.toMap());
    updated.info.lightExposure = switch (result.estimatedLevel) {
      EstimatedLightLevel.low => 'LOW',
      EstimatedLightLevel.moderate => 'MEDIUM',
      EstimatedLightLevel.high => 'HIGH',
    };
    setState(() => _saving = true);
    try {
      final response =
          await widget.env.http.put('plant/${plant.id}', updated.toMap());
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (!mounted) return;
      if (response.statusCode != 200 || body is! Map<String, dynamic>) {
        throw StateError('Unable to update plant light profile');
      }
      final PlantDTO saved = PlantDTO.fromJson(body);
      widget.env.plants = widget.env.plants
          .map((candidate) => candidate.id == saved.id ? saved : candidate)
          .toList();
      setState(() => _plant = saved);
      widget.env.toastManager.showToast(
        context,
        ToastNotificationType.success,
        AppLocalizations.of(context).lightProfileSaved,
      );
    } catch (error, stackTrace) {
      widget.env.logger.error(error, stackTrace);
      if (mounted) {
        widget.env.toastManager.showToast(
          context,
          ToastNotificationType.error,
          AppLocalizations.of(context).generalError,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.lightPlacementCheck)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  localizations.lightCheckIntro,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (widget.initialPlant == null)
                  DropdownButtonFormField<PlantDTO>(
                    key: const ValueKey<String>('light-check-plant'),
                    value: _plant,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: localizations.plantOptional,
                      prefixIcon: const Icon(Icons.local_florist_outlined),
                      suffixIcon: _loadingSpecies
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                    items: widget.env.plants
                        .map(
                          (plant) => DropdownMenuItem<PlantDTO>(
                            value: plant,
                            child: Text(
                              plant.info.personalName ?? plant.species ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _selectPlant,
                  ),
                if (_species?.care.lightRequirement != null) ...[
                  const SizedBox(height: 10),
                  _RequirementCard(
                    label: localizations.plantNeedsLight(
                      _requirementLabel(
                        localizations,
                        _species!.care.lightRequirement!,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _enumDropdown<NaturalLightDuration>(
                  key: const ValueKey<String>('light-check-duration'),
                  label: localizations.directLightDuration,
                  icon: Icons.schedule_outlined,
                  value: _directLight,
                  values: NaturalLightDuration.values,
                  labelFor: (value) => _durationLabel(localizations, value),
                  onChanged: (value) => setState(() {
                    _directLight = value;
                    _result = null;
                  }),
                ),
                const SizedBox(height: 14),
                _enumDropdown<WindowDistance>(
                  key: const ValueKey<String>('light-check-distance'),
                  label: localizations.distanceFromWindow,
                  icon: Icons.straighten_outlined,
                  value: _distance,
                  values: WindowDistance.values,
                  labelFor: (value) => _distanceLabel(localizations, value),
                  onChanged: (value) => setState(() {
                    _distance = value;
                    _result = null;
                  }),
                ),
                const SizedBox(height: 14),
                _enumDropdown<WindowObstruction>(
                  key: const ValueKey<String>('light-check-obstruction'),
                  label: localizations.windowView,
                  icon: Icons.window_outlined,
                  value: _obstruction,
                  values: WindowObstruction.values,
                  labelFor: (value) => _obstructionLabel(localizations, value),
                  onChanged: (value) => setState(() {
                    _obstruction = value;
                    _result = null;
                  }),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const ValueKey<String>('light-check-submit'),
                  onPressed: _checkPlacement,
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: Text(localizations.checkPlantLight),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 18),
                  _buildResult(localizations, _result!),
                ],
                const SizedBox(height: 18),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.honestLightEstimate,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 5),
                        Text(localizations.lightEstimateDisclaimer),
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://extension.umn.edu/planting-and-growing-guides/lighting-indoor-plants',
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(localizations.readExtensionGuidance),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(
    AppLocalizations localizations,
    LightExposureResult result,
  ) {
    final colors = Theme.of(context).colorScheme;
    final (IconData, Color) presentation = switch (result.match) {
      LightPlacementMatch.suitable => (
          Icons.check_circle_outline,
          colors.primary
        ),
      LightPlacementMatch.tooLow => (Icons.arrow_upward, colors.tertiary),
      LightPlacementMatch.tooHigh => (Icons.arrow_downward, colors.tertiary),
      LightPlacementMatch.unknownRequirement => (
          Icons.info_outline,
          colors.secondary
        ),
    };
    return Card(
      key: const ValueKey<String>('light-check-result'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(presentation.$1, color: presentation.$2, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localizations.estimatedLight(
                      _estimatedLabel(localizations, result.estimatedLevel),
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_matchGuidance(localizations, result.match)),
            if (_plant != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _saving ? null : _saveObservedLight,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(localizations.saveObservedLight),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _enumDropdown<T>({
    required Key key,
    required String label,
    required IconData icon,
    required T value,
    required List<T> values,
    required String Function(T) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      key: key,
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: values
          .map(
            (entry) => DropdownMenuItem<T>(
              value: entry,
              child: Text(labelFor(entry)),
            ),
          )
          .toList(),
      onChanged: (entry) {
        if (entry != null) onChanged(entry);
      },
    );
  }

  String _requirementLabel(AppLocalizations localizations, String value) {
    return switch (value) {
      'LOW' => localizations.low,
      'HIGH' => localizations.high,
      _ => localizations.moderate,
    };
  }

  String _durationLabel(
    AppLocalizations localizations,
    NaturalLightDuration value,
  ) {
    return switch (value) {
      NaturalLightDuration.none => localizations.noDirectLight,
      NaturalLightDuration.underTwoHours => localizations.underTwoHours,
      NaturalLightDuration.twoToFourHours => localizations.twoToFourHours,
      NaturalLightDuration.overFourHours => localizations.overFourHours,
    };
  }

  String _distanceLabel(
    AppLocalizations localizations,
    WindowDistance value,
  ) {
    return switch (value) {
      WindowDistance.near => localizations.nearWindow,
      WindowDistance.middle => localizations.middleFromWindow,
      WindowDistance.aboutTenFeet => localizations.aboutTenFeetFromWindow,
      WindowDistance.far => localizations.farFromWindow,
    };
  }

  String _obstructionLabel(
    AppLocalizations localizations,
    WindowObstruction value,
  ) {
    return switch (value) {
      WindowObstruction.open => localizations.openWindowView,
      WindowObstruction.clear => localizations.clearWindowView,
      WindowObstruction.filtered => localizations.filteredWindowView,
      WindowObstruction.blocked => localizations.blockedWindowView,
    };
  }

  String _estimatedLabel(
    AppLocalizations localizations,
    EstimatedLightLevel value,
  ) {
    return switch (value) {
      EstimatedLightLevel.low => localizations.low,
      EstimatedLightLevel.moderate => localizations.moderate,
      EstimatedLightLevel.high => localizations.high,
    };
  }

  String _matchGuidance(
    AppLocalizations localizations,
    LightPlacementMatch value,
  ) {
    return switch (value) {
      LightPlacementMatch.tooLow => localizations.lightPlacementTooLow,
      LightPlacementMatch.suitable => localizations.lightPlacementSuitable,
      LightPlacementMatch.tooHigh => localizations.lightPlacementTooHigh,
      LightPlacementMatch.unknownRequirement =>
        localizations.lightPlacementUnknownRequirement,
    };
  }
}

class _RequirementCard extends StatelessWidget {
  final String label;

  const _RequirementCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.eco_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
