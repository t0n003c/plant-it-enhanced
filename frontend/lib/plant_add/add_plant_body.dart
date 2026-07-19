import 'package:flutter/material.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/info_entries.dart';
import 'package:plant_it/plant_care_profile_editor.dart';

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
          PlantCareProfileEditor(
            info: widget.toCreate.info,
            onChanged: () => setState(() {}),
            footer: [
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
