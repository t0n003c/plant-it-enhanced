import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/info_entries.dart';

class PlantCareProfileEditor extends StatelessWidget {
  final PlantInfoDTO info;
  final VoidCallback onChanged;
  final bool initiallyExpanded;
  final List<Widget> footer;

  const PlantCareProfileEditor({
    super.key,
    required this.info,
    required this.onChanged,
    this.initiallyExpanded = true,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ExpansionTile(
      key: const ValueKey<String>('personalized-care-profile-editor'),
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        localizations.personalizedCareProfile,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(localizations.personalizedCareProfileHint),
      children: [
        _profileDropdown(
          context: context,
          label: localizations.growingEnvironment,
          value: info.growingEnvironment,
          options: {
            'INDOOR': localizations.indoors,
            'OUTDOOR': localizations.outdoors,
            'GREENHOUSE': localizations.greenhouse,
          },
          onChanged: (value) {
            info.growingEnvironment = value;
            onChanged();
          },
        ),
        _profileDropdown(
          context: context,
          label: localizations.observedLight,
          value: info.lightExposure,
          options: {
            'LOW': localizations.low,
            'MEDIUM': localizations.moderate,
            'HIGH': localizations.high,
          },
          onChanged: (value) {
            info.lightExposure = value;
            onChanged();
          },
        ),
        _profileDropdown(
          context: context,
          label: localizations.nearestWindow,
          value: info.windowDirection,
          options: {
            'NONE': localizations.none,
            'N': localizations.north,
            'E': localizations.east,
            'S': localizations.south,
            'W': localizations.west,
          },
          onChanged: (value) {
            info.windowDirection = value;
            onChanged();
          },
        ),
        EditableSimpleInfoEntry(
          title: localizations.potDiameterCm,
          value: info.potDiameterCm?.toString(),
          onlyNumber: true,
          onChanged: (value) {
            info.potDiameterCm = double.tryParse(value);
            onChanged();
          },
        ),
        _profileDropdown(
          context: context,
          label: localizations.potMaterial,
          value: info.potMaterial,
          options: {
            'PLASTIC': localizations.plastic,
            'TERRACOTTA': localizations.terracotta,
            'GLAZED': localizations.glazedCeramic,
            'SELF_WATERING': localizations.selfWatering,
          },
          onChanged: (value) {
            info.potMaterial = value;
            onChanged();
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(localizations.hasDrainageHole),
          value: info.hasDrainage ?? true,
          onChanged: (value) {
            info.hasDrainage = value;
            onChanged();
          },
        ),
        EditableSimpleInfoEntry(
          title: localizations.soilOrGrowingMedium,
          value: info.soilType,
          onChanged: (value) {
            info.soilType = value;
            onChanged();
          },
        ),
        EditableDateInfoEntry(
          title: localizations.lastWatered,
          emptyHint: localizations.noWateringDate,
          value: _parseDate(info.lastWateredAt),
          onChange: (date) {
            info.lastWateredAt = date?.toIso8601String();
            onChanged();
          },
        ),
        EditableDateInfoEntry(
          title: localizations.lastRepotted,
          emptyHint: localizations.noRepottingDate,
          value: _parseDate(info.lastRepottedAt),
          onChange: (date) {
            info.lastRepottedAt = date?.toIso8601String();
            onChanged();
          },
        ),
        ...footer,
      ],
    );
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Widget _profileDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DropdownButtonFormField<String>(
        value: options.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
