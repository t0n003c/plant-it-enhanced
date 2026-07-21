import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/event/add_new_event.dart';
import 'package:plant_it/health/plant_health_assessment.dart';
import 'package:url_launcher/url_launcher.dart';

class PlantHealthPage extends StatefulWidget {
  final Environment env;
  final PlantDTO? initialPlant;

  const PlantHealthPage({
    super.key,
    required this.env,
    this.initialPlant,
  });

  @override
  State<PlantHealthPage> createState() => _PlantHealthPageState();
}

class _PlantHealthPageState extends State<PlantHealthPage> {
  static const int _lastStep = 3;
  final ImagePicker _imagePicker = ImagePicker();
  final Set<PlantHealthSymptom> _symptoms = {};
  int _step = 0;
  PlantDTO? _plant;
  XFile? _wholePlantPhoto;
  XFile? _affectedAreaPhoto;
  ObservedSoilMoisture _soilMoisture = ObservedSoilMoisture.unknown;
  ObservedPlantLight _light = ObservedPlantLight.unknown;
  bool _poorAirflowOrWetLeaves = false;
  bool _recentMoveOrCareChange = false;
  List<PlantHealthAssessmentResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _plant = widget.initialPlant;
  }

  Future<void> _pickPhoto({
    required bool wholePlant,
    required ImageSource source,
  }) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image == null || !mounted) return;
    setState(() {
      if (wholePlant) {
        _wholePlantPhoto = image;
      } else {
        _affectedAreaPhoto = image;
      }
    });
  }

  void _continue() {
    if (_step == 1 && _symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).selectSymptom)),
      );
      return;
    }
    if (_step == 2) {
      _results = PlantHealthAssessment.evaluate(
        PlantHealthAssessmentInput(
          symptoms: _symptoms,
          soilMoisture: _soilMoisture,
          light: _light,
          poorAirflowOrWetLeaves: _poorAirflowOrWetLeaves,
          recentMoveOrCareChange: _recentMoveOrCareChange,
        ),
      );
    }
    if (_step < _lastStep) setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
  }

  void _reset() {
    setState(() {
      _step = 0;
      _wholePlantPhoto = null;
      _affectedAreaPhoto = null;
      _symptoms.clear();
      _soilMoisture = ObservedSoilMoisture.unknown;
      _light = ObservedPlantLight.unknown;
      _poorAirflowOrWetLeaves = false;
      _recentMoveOrCareChange = false;
      _results = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.plantHealthCheck)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.stepOf(_step + 1, _lastStep + 1),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(_stepTitle(localizations)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / (_lastStep + 1),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: ListView(
                      key: ValueKey<int>(_step),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      children: [_buildStep(localizations)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              OutlinedButton.icon(
                key: const ValueKey<String>('health-check-back'),
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
                label: Text(localizations.back),
              ),
              const Spacer(),
              if (_step == _lastStep)
                FilledButton.icon(
                  key: const ValueKey<String>('health-check-reset'),
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.startOver),
                )
              else
                FilledButton.icon(
                  key: const ValueKey<String>('health-check-continue'),
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(localizations.continueLabel),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle(AppLocalizations localizations) {
    return switch (_step) {
      0 => localizations.choosePlantAndPhotos,
      1 => localizations.visibleSymptoms,
      2 => localizations.growingConditions,
      _ => localizations.healthCheckResults,
    };
  }

  Widget _buildStep(AppLocalizations localizations) {
    return switch (_step) {
      0 => _buildPlantAndPhotoStep(localizations),
      1 => _buildSymptomStep(localizations),
      2 => _buildConditionsStep(localizations),
      _ => _buildResultsStep(localizations),
    };
  }

  Widget _buildPlantAndPhotoStep(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.healthCheckPhotoIntro,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        if (widget.initialPlant == null) ...[
          DropdownButtonFormField<PlantDTO>(
            key: const ValueKey<String>('health-check-plant'),
            value: _plant,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: localizations.plantOptional,
              prefixIcon: const Icon(Icons.local_florist_outlined),
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
            onChanged: (value) => setState(() => _plant = value),
          ),
          const SizedBox(height: 14),
        ],
        _HealthPhotoSlot(
          icon: Icons.yard_outlined,
          title: localizations.wholePlantView,
          hint: localizations.healthWholePlantHint,
          photo: _wholePlantPhoto,
          onCamera: () =>
              _pickPhoto(wholePlant: true, source: ImageSource.camera),
          onGallery: () =>
              _pickPhoto(wholePlant: true, source: ImageSource.gallery),
        ),
        const SizedBox(height: 12),
        _HealthPhotoSlot(
          icon: Icons.center_focus_strong,
          title: localizations.affectedArea,
          hint: localizations.healthAffectedAreaHint,
          photo: _affectedAreaPhoto,
          onCamera: () =>
              _pickPhoto(wholePlant: false, source: ImageSource.camera),
          onGallery: () =>
              _pickPhoto(wholePlant: false, source: ImageSource.gallery),
        ),
        const SizedBox(height: 14),
        _NoticeCard(
          icon: Icons.lock_outline,
          text: localizations.healthPhotoPrivacy,
        ),
      ],
    );
  }

  Widget _buildSymptomStep(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.selectAllSymptoms,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlantHealthSymptom.values.map((symptom) {
            return FilterChip(
              key: ValueKey<String>('health-symptom-${symptom.name}'),
              selected: _symptoms.contains(symptom),
              avatar: Icon(_symptomIcon(symptom), size: 19),
              label: Text(_symptomLabel(localizations, symptom)),
              onSelected: (selected) => setState(() {
                if (selected) {
                  _symptoms.add(symptom);
                } else {
                  _symptoms.remove(symptom);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _NoticeCard(
          icon: Icons.visibility_outlined,
          text: localizations.checkLeafUndersides,
        ),
      ],
    );
  }

  Widget _buildConditionsStep(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.conditionsImproveTriage,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ObservedSoilMoisture>(
          key: const ValueKey<String>('health-soil-moisture'),
          value: _soilMoisture,
          decoration: InputDecoration(
            labelText: localizations.currentSoilMoisture,
            prefixIcon: const Icon(Icons.water_drop_outlined),
          ),
          items: ObservedSoilMoisture.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_soilLabel(localizations, value)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(
            () => _soilMoisture = value ?? ObservedSoilMoisture.unknown,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<ObservedPlantLight>(
          key: const ValueKey<String>('health-observed-light'),
          value: _light,
          decoration: InputDecoration(
            labelText: localizations.currentLight,
            prefixIcon: const Icon(Icons.wb_sunny_outlined),
          ),
          items: ObservedPlantLight.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_lightLabel(localizations, value)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(
            () => _light = value ?? ObservedPlantLight.unknown,
          ),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _poorAirflowOrWetLeaves,
          title: Text(localizations.wetLeavesOrPoorAirflow),
          onChanged: (value) => setState(
            () => _poorAirflowOrWetLeaves = value ?? false,
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _recentMoveOrCareChange,
          title: Text(localizations.recentMoveOrCareChange),
          onChanged: (value) => setState(
            () => _recentMoveOrCareChange = value ?? false,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsStep(AppLocalizations localizations) {
    final int photoCount = (_wholePlantPhoto == null ? 0 : 1) +
        (_affectedAreaPhoto == null ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.healthResultsIntro,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (photoCount > 0) ...[
          const SizedBox(height: 8),
          Text(localizations.localPhotosKept(photoCount)),
        ],
        const SizedBox(height: 16),
        ..._results.map(
          (result) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HealthResultCard(
              result: result,
              copy: _concernCopy(localizations, result.concern),
            ),
          ),
        ),
        _NoticeCard(
          icon: Icons.info_outline,
          text: localizations.healthCheckDisclaimer,
        ),
        if (_plant != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddNewEventPage(
                  env: widget.env,
                  plant: _plant,
                ),
              ),
            ),
            icon: const Icon(Icons.edit_note_outlined),
            label: Text(localizations.recordPlantObservation),
          ),
        ],
      ],
    );
  }

  String _symptomLabel(
    AppLocalizations localizations,
    PlantHealthSymptom symptom,
  ) {
    return switch (symptom) {
      PlantHealthSymptom.wilting => localizations.symptomWilting,
      PlantHealthSymptom.yellowLeaves => localizations.symptomYellowLeaves,
      PlantHealthSymptom.brownCrispyEdges =>
        localizations.symptomBrownCrispyEdges,
      PlantHealthSymptom.darkOrWetSpots => localizations.symptomDarkWetSpots,
      PlantHealthSymptom.paleOrLeggyGrowth => localizations.symptomPaleLeggy,
      PlantHealthSymptom.bleachedLeaves => localizations.symptomBleachedLeaves,
      PlantHealthSymptom.visiblePestsOrWebbing =>
        localizations.symptomPestsWebbing,
      PlantHealthSymptom.whitePowder => localizations.symptomWhitePowder,
    };
  }

  IconData _symptomIcon(PlantHealthSymptom symptom) {
    return switch (symptom) {
      PlantHealthSymptom.wilting => Icons.spa_outlined,
      PlantHealthSymptom.yellowLeaves => Icons.eco_outlined,
      PlantHealthSymptom.brownCrispyEdges => Icons.dry_outlined,
      PlantHealthSymptom.darkOrWetSpots => Icons.blur_circular,
      PlantHealthSymptom.paleOrLeggyGrowth => Icons.height,
      PlantHealthSymptom.bleachedLeaves => Icons.brightness_high_outlined,
      PlantHealthSymptom.visiblePestsOrWebbing => Icons.bug_report_outlined,
      PlantHealthSymptom.whitePowder => Icons.grain,
    };
  }

  String _soilLabel(
    AppLocalizations localizations,
    ObservedSoilMoisture value,
  ) {
    return switch (value) {
      ObservedSoilMoisture.wet => localizations.soilWet,
      ObservedSoilMoisture.moist => localizations.soilMoist,
      ObservedSoilMoisture.dry => localizations.soilDry,
      ObservedSoilMoisture.unknown => localizations.notSure,
    };
  }

  String _lightLabel(
    AppLocalizations localizations,
    ObservedPlantLight value,
  ) {
    return switch (value) {
      ObservedPlantLight.low => localizations.low,
      ObservedPlantLight.moderate => localizations.moderate,
      ObservedPlantLight.bright => localizations.brightIndirectLight,
      ObservedPlantLight.direct => localizations.directSun,
      ObservedPlantLight.unknown => localizations.notSure,
    };
  }

  _ConcernCopy _concernCopy(
    AppLocalizations localizations,
    PlantHealthConcern concern,
  ) {
    return switch (concern) {
      PlantHealthConcern.waterloggedRoots => _ConcernCopy(
          title: localizations.concernWaterloggedRoots,
          description: localizations.concernWaterloggedRootsDescription,
          nextCheck: localizations.concernWaterloggedRootsCheck,
          sourceUrl:
              'https://extension.umd.edu/resource/diagnose-indoor-plant-problems',
        ),
      PlantHealthConcern.droughtStress => _ConcernCopy(
          title: localizations.concernDroughtStress,
          description: localizations.concernDroughtStressDescription,
          nextCheck: localizations.concernDroughtStressCheck,
          sourceUrl:
              'https://extension.umd.edu/resource/diagnose-indoor-plant-problems',
        ),
      PlantHealthConcern.pestPressure => _ConcernCopy(
          title: localizations.concernPestPressure,
          description: localizations.concernPestPressureDescription,
          nextCheck: localizations.concernPestPressureCheck,
          sourceUrl:
              'https://extension.umd.edu/resource/ipm-prevent-identify-and-manage-plant-problems',
        ),
      PlantHealthConcern.leafSpotRisk => _ConcernCopy(
          title: localizations.concernLeafSpot,
          description: localizations.concernLeafSpotDescription,
          nextCheck: localizations.concernLeafSpotCheck,
          sourceUrl:
              'https://extension.umd.edu/resources/yard-garden/indoor-plants/indoor-plant-diseases',
        ),
      PlantHealthConcern.lowLightStress => _ConcernCopy(
          title: localizations.concernLowLight,
          description: localizations.concernLowLightDescription,
          nextCheck: localizations.concernLowLightCheck,
          sourceUrl:
              'https://extension.umn.edu/planting-and-growing-guides/lighting-indoor-plants',
        ),
      PlantHealthConcern.excessLightStress => _ConcernCopy(
          title: localizations.concernExcessLight,
          description: localizations.concernExcessLightDescription,
          nextCheck: localizations.concernExcessLightCheck,
          sourceUrl:
              'https://extension.umn.edu/planting-and-growing-guides/lighting-indoor-plants',
        ),
      PlantHealthConcern.powderyMildewRisk => _ConcernCopy(
          title: localizations.concernPowderyMildew,
          description: localizations.concernPowderyMildewDescription,
          nextCheck: localizations.concernPowderyMildewCheck,
          sourceUrl:
              'https://extension.umd.edu/resources/yard-garden/indoor-plants/indoor-plant-diseases',
        ),
      PlantHealthConcern.needsCloserInspection => _ConcernCopy(
          title: localizations.concernCloserInspection,
          description: localizations.concernCloserInspectionDescription,
          nextCheck: localizations.concernCloserInspectionCheck,
          sourceUrl:
              'https://extension.umd.edu/resource/diagnose-indoor-plant-problems',
        ),
    };
  }
}

class _HealthPhotoSlot extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final XFile? photo;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _HealthPhotoSlot({
    required this.icon,
    required this.title,
    required this.hint,
    required this.photo,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        photo?.name ?? hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (photo != null)
                  Icon(Icons.check_circle, color: colors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(AppLocalizations.of(context).takePlantPhoto),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(AppLocalizations.of(context).choosePlantPhoto),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcernCopy {
  final String title;
  final String description;
  final String nextCheck;
  final String sourceUrl;

  const _ConcernCopy({
    required this.title,
    required this.description,
    required this.nextCheck,
    required this.sourceUrl,
  });
}

class _HealthResultCard extends StatelessWidget {
  final PlantHealthAssessmentResult result;
  final _ConcernCopy copy;

  const _HealthResultCard({required this.result, required this.copy});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    copy.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.score >= 8
                        ? localizations.strongPattern
                        : localizations.possiblePattern,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(copy.description),
            const SizedBox(height: 12),
            Text(
              localizations.nextSafeCheck,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(copy.nextCheck),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => launchUrl(Uri.parse(copy.sourceUrl)),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(localizations.readExtensionGuidance),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NoticeCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
