import 'package:flutter/material.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/info_entries.dart';

class AddPlantBody extends StatefulWidget {
  final PlantDTO toCreate;
  final SpeciesCareInfoDTO care;
  final bool createSuggestedReminder;
  final ValueChanged<bool> onCreateSuggestedReminderChanged;

  const AddPlantBody({
    super.key,
    required this.toCreate,
    required this.care,
    required this.createSuggestedReminder,
    required this.onCreateSuggestedReminderChanged,
  });

  @override
  State<StatefulWidget> createState() => _AddPlantBodyState();
}

class _AddPlantBodyState extends State<AddPlantBody> {
  late bool _createSuggestedReminder;

  @override
  void initState() {
    super.initState();
    _createSuggestedReminder = widget.createSuggestedReminder;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          const SizedBox(
            height: 20,
          ),
          EditableSimpleInfoEntry(
            title: AppLocalizations.of(context).name,
            value: widget.toCreate.info.personalName,
            onChanged: (name) => widget.toCreate.info.personalName = name,
            onlyNumber: false,
          ),
          EditableDateInfoEntry(
            title: AppLocalizations.of(context).birthday,
            emptyHint: AppLocalizations.of(context).noBirthday,
            value: DateTime.now(),
            onChange: (d) {
              if (d != null) {
                widget.toCreate.info.startDate = d.toIso8601String();
              } else {
                widget.toCreate.info.startDate = null;
              }
            },
          ),
          EditableCurrencyInfoEntry(
            currency: widget.toCreate.info.currencySymbol,
            title: AppLocalizations.of(context).purchasedPrice,
            value: widget.toCreate.info.purchasedPrice,
            onChangeCurrency: (c) => widget.toCreate.info.currencySymbol = c,
            onChangeValue: (p) => widget.toCreate.info.purchasedPrice = p,
          ),
          EditableSimpleInfoEntry(
            title: AppLocalizations.of(context).seller,
            value: widget.toCreate.info.seller.toString(),
            onChanged: (s) => widget.toCreate.info.seller = s,
            onlyNumber: false,
          ),
          EditableSimpleInfoEntry(
            title: AppLocalizations.of(context).location,
            value: widget.toCreate.info.location.toString(),
            onChanged: (l) => widget.toCreate.info.location = l,
            onlyNumber: false,
          ),
          const SizedBox(height: 18),
          ExpansionTile(
            initiallyExpanded: true,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              AppLocalizations.of(context).personalizedCareProfile,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              AppLocalizations.of(context).personalizedCareProfileHint,
            ),
            children: [
              _profileDropdown(
                label: AppLocalizations.of(context).growingEnvironment,
                value: widget.toCreate.info.growingEnvironment,
                options: {
                  'INDOOR': AppLocalizations.of(context).indoors,
                  'OUTDOOR': AppLocalizations.of(context).outdoors,
                  'GREENHOUSE': AppLocalizations.of(context).greenhouse,
                },
                onChanged: (value) => setState(
                  () => widget.toCreate.info.growingEnvironment = value,
                ),
              ),
              _profileDropdown(
                label: AppLocalizations.of(context).observedLight,
                value: widget.toCreate.info.lightExposure,
                options: {
                  'LOW': AppLocalizations.of(context).low,
                  'MEDIUM': AppLocalizations.of(context).moderate,
                  'HIGH': AppLocalizations.of(context).high,
                },
                onChanged: (value) => setState(
                  () => widget.toCreate.info.lightExposure = value,
                ),
              ),
              _profileDropdown(
                label: AppLocalizations.of(context).nearestWindow,
                value: widget.toCreate.info.windowDirection,
                options: {
                  'NONE': AppLocalizations.of(context).none,
                  'N': AppLocalizations.of(context).north,
                  'E': AppLocalizations.of(context).east,
                  'S': AppLocalizations.of(context).south,
                  'W': AppLocalizations.of(context).west,
                },
                onChanged: (value) =>
                    widget.toCreate.info.windowDirection = value,
              ),
              EditableSimpleInfoEntry(
                title: AppLocalizations.of(context).potDiameterCm,
                value: widget.toCreate.info.potDiameterCm?.toString(),
                onlyNumber: true,
                onChanged: (value) => setState(() {
                  widget.toCreate.info.potDiameterCm = double.tryParse(value);
                }),
              ),
              _profileDropdown(
                label: AppLocalizations.of(context).potMaterial,
                value: widget.toCreate.info.potMaterial,
                options: {
                  'PLASTIC': AppLocalizations.of(context).plastic,
                  'TERRACOTTA': AppLocalizations.of(context).terracotta,
                  'GLAZED': AppLocalizations.of(context).glazedCeramic,
                  'SELF_WATERING': AppLocalizations.of(context).selfWatering,
                },
                onChanged: (value) => setState(
                  () => widget.toCreate.info.potMaterial = value,
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context).hasDrainageHole),
                value: widget.toCreate.info.hasDrainage ?? true,
                onChanged: (value) => setState(
                  () => widget.toCreate.info.hasDrainage = value,
                ),
              ),
              EditableSimpleInfoEntry(
                title: AppLocalizations.of(context).soilOrGrowingMedium,
                value: widget.toCreate.info.soilType,
                onChanged: (value) => setState(
                  () => widget.toCreate.info.soilType = value,
                ),
              ),
              EditableDateInfoEntry(
                title: AppLocalizations.of(context).lastWatered,
                emptyHint: AppLocalizations.of(context).noWateringDate,
                onChange: (date) => widget.toCreate.info.lastWateredAt =
                    date?.toIso8601String(),
              ),
              EditableDateInfoEntry(
                title: AppLocalizations.of(context).lastRepotted,
                emptyHint: AppLocalizations.of(context).noRepottingDate,
                onChange: (date) => widget.toCreate.info.lastRepottedAt =
                    date?.toIso8601String(),
              ),
              Card(
                margin: const EdgeInsets.only(top: 16),
                color: const Color.fromRGBO(24, 44, 37, 1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).suggestedWateringSummary(
                          _suggestedWateringIntervalDays(),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context).careScheduleDisclaimer,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          AppLocalizations.of(context)
                              .createSuggestedWateringReminder,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: _createSuggestedReminder,
                        onChanged: (value) {
                          setState(() => _createSuggestedReminder = value);
                          widget.onCreateSuggestedReminderChanged(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          EditableFullWidthInfoEntry(
            value: widget.toCreate.info.note,
            title: AppLocalizations.of(context).note,
            onChanged: (n) => widget.toCreate.info.note = n,
          ),
          const SizedBox(
            height: 100,
          ),
        ]),
      ),
    );
  }

  Widget _profileDropdown({
    required String label,
    required String? value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.entries
            .map((entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  int _suggestedWateringIntervalDays() {
    final int moisture = widget.care.soilHumidity ?? 6;
    double days = switch (moisture) {
      >= 9 => 3,
      >= 7 => 4,
      >= 5 => 7,
      >= 3 => 12,
      _ => 18,
    };
    if (widget.toCreate.info.growingEnvironment == 'OUTDOOR') days *= .8;
    if (widget.toCreate.info.growingEnvironment == 'GREENHOUSE') days *= .9;
    if (widget.toCreate.info.lightExposure == 'HIGH') days *= .8;
    if (widget.toCreate.info.lightExposure == 'LOW') days *= 1.25;
    if ((widget.toCreate.info.potDiameterCm ?? 20) <= 12) days *= .82;
    if ((widget.toCreate.info.potDiameterCm ?? 20) >= 30) days *= 1.18;
    if (widget.toCreate.info.potMaterial == 'TERRACOTTA') days *= .82;
    if (widget.toCreate.info.potMaterial == 'SELF_WATERING') days *= 1.35;
    if (widget.toCreate.info.hasDrainage == false) days *= 1.3;
    return days.round().clamp(2, 30).toInt();
  }
}
