import 'package:flutter/material.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/info_entries.dart';

class SpeciesDetailsTab extends StatefulWidget {
  final SpeciesDTO species;
  final bool isLoading;
  final VoidCallback? onRefreshCare;
  final bool refreshingCare;
  const SpeciesDetailsTab({
    super.key,
    required this.species,
    required this.isLoading,
    this.onRefreshCare,
    this.refreshingCare = false,
  });

  @override
  State<StatefulWidget> createState() => _SpeciesDetailsTabState();
}

class _SpeciesDetailsTabState extends State<SpeciesDetailsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          InfoGroup(
            title: AppLocalizations.of(context).scientificClassification,
            children: widget.isLoading
                ? generateSkeleton(3, widget.isLoading)
                : [
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).family,
                        value: widget.species.family),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).genus,
                        value: widget.species.genus),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).species,
                        value: widget.species.species)
                  ],
          ),
          InfoGroup(
            title: AppLocalizations.of(context).info,
            children: widget.isLoading
                ? generateSkeleton(1, widget.isLoading)
                : [
                    FullWidthInfoEntry(
                      title: AppLocalizations.of(context).synonyms,
                      value: widget.species.synonyms?.join(", "),
                    )
                  ],
          ),
          InfoGroup(
            title: AppLocalizations.of(context).care,
            children: widget.isLoading
                ? generateSkeleton(7, widget.isLoading)
                : [
                    if (widget.refreshingCare && widget.onRefreshCare == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (widget.species.care.lightRequirement != null)
                      _CareGuidanceCard(
                        icon: Icons.wb_sunny_outlined,
                        title: AppLocalizations.of(context).sunlight,
                        level: _requirementLabel(
                          context,
                          widget.species.care.lightRequirement!,
                        ),
                        guidance: _lightGuidance(
                          context,
                          widget.species.care.lightRequirement!,
                        ),
                      ),
                    if (widget.species.care.waterRequirement != null)
                      _CareGuidanceCard(
                        icon: Icons.water_drop_outlined,
                        title: AppLocalizations.of(context).watering,
                        level: _requirementLabel(
                          context,
                          widget.species.care.waterRequirement!,
                        ),
                        guidance: _waterGuidance(
                          context,
                          widget.species.care.waterRequirement!,
                        ),
                      ),
                    if (widget.species.care.lightRequirement != null ||
                        widget.species.care.waterRequirement != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          AppLocalizations.of(context).careGuidanceDisclaimer,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    SimpleInfoEntry(
                      title: AppLocalizations.of(context).light,
                      value: widget.species.care.light == null
                          ? null
                          : AppLocalizations.of(context)
                              .nOutOf(widget.species.care.light ?? 0, 10),
                    ),
                    SimpleInfoEntry(
                      title: AppLocalizations.of(context).humidity,
                      value: widget.species.care.humidity == null
                          ? null
                          : AppLocalizations.of(context)
                              .nOutOf(widget.species.care.humidity ?? 0, 10),
                    ),
                    SimpleInfoEntry(
                      title: AppLocalizations.of(context).soilMoisture,
                      value: widget.species.care.soilHumidity == null
                          ? null
                          : AppLocalizations.of(context)
                              .nOutOf(widget.species.care.soilHumidity!, 10),
                    ),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).maxTemp,
                        value: widget.species.care.maxTemp == null
                            ? null
                            : AppLocalizations.of(context)
                                .temp(widget.species.care.maxTemp ?? 0)),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).minTemp,
                        value: widget.species.care.minTemp == null
                            ? null
                            : AppLocalizations.of(context)
                                .temp(widget.species.care.minTemp ?? 0)),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).maxPh,
                        value: widget.species.care.phMax?.toString()),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).minPh,
                        value: widget.species.care.phMin?.toString()),
                    SimpleInfoEntry(
                      title: AppLocalizations.of(context).careDataSource,
                      value: _careSourceLabel(context),
                    ),
                    SimpleInfoEntry(
                      title: AppLocalizations.of(context).careDataLastVerified,
                      value: widget.species.care.lastVerifiedAt == null
                          ? null
                          : MaterialLocalizations.of(context).formatMediumDate(
                              widget.species.care.lastVerifiedAt!.toLocal(),
                            ),
                    ),
                    if (widget.onRefreshCare != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: OutlinedButton.icon(
                          onPressed: widget.refreshingCare
                              ? null
                              : widget.onRefreshCare,
                          icon: widget.refreshingCare
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(
                            AppLocalizations.of(context).refreshCareGuide,
                          ),
                        ),
                      ),
                  ],
          )
        ],
      ),
    );
  }

  String _requirementLabel(BuildContext context, String requirement) {
    switch (requirement) {
      case 'LOW':
        return AppLocalizations.of(context).low;
      case 'HIGH':
        return AppLocalizations.of(context).high;
      default:
        return AppLocalizations.of(context).moderate;
    }
  }

  String _lightGuidance(BuildContext context, String requirement) {
    switch (requirement) {
      case 'LOW':
        return AppLocalizations.of(context).lowLightGuidance;
      case 'HIGH':
        return AppLocalizations.of(context).highLightGuidance;
      default:
        return AppLocalizations.of(context).moderateLightGuidance;
    }
  }

  String? _careSourceLabel(BuildContext context) {
    if (widget.species.care.source == 'TREFLE') {
      return AppLocalizations.of(context).careDataProvidedByTrefle;
    }
    if (widget.species.care.source == 'PERENUAL') {
      return AppLocalizations.of(context).careDataProvidedByPerenual;
    }
    return widget.species.care.source;
  }

  String _waterGuidance(BuildContext context, String requirement) {
    switch (requirement) {
      case 'LOW':
        return AppLocalizations.of(context).lowWaterGuidance;
      case 'HIGH':
        return AppLocalizations.of(context).highWaterGuidance;
      default:
        return AppLocalizations.of(context).moderateWaterGuidance;
    }
  }
}

class _CareGuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String level;
  final String guidance;

  const _CareGuidanceCard({
    required this.icon,
    required this.title,
    required this.level,
    required this.guidance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromRGBO(24, 44, 37, 1),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.lightGreenAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title · $level',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(guidance, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
