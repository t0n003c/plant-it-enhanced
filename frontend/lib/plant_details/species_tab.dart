import 'package:flutter/material.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/info_entries.dart';
import 'package:url_launcher/url_launcher.dart';

class SpeciesDetailsTab extends StatefulWidget {
  final SpeciesDTO species;
  final bool isLoading;
  final VoidCallback? onRefreshCare;
  final bool refreshingCare;
  final bool showImageCredit;
  const SpeciesDetailsTab({
    super.key,
    required this.species,
    required this.isLoading,
    this.onRefreshCare,
    this.refreshingCare = false,
    this.showImageCredit = false,
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
            title: AppLocalizations.of(context).info,
            children: widget.isLoading
                ? generateSkeleton(5, widget.isLoading)
                : [
                    Text(
                      AppLocalizations.of(context).scientificClassification,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).family,
                        value: widget.species.family),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).genus,
                        value: widget.species.genus),
                    SimpleInfoEntry(
                        title: AppLocalizations.of(context).species,
                        value: widget.species.species),
                    if (widget.species.catalogVariant?.trim().isNotEmpty ==
                        true)
                      SimpleInfoEntry(
                        title: AppLocalizations.of(context).catalogVariant,
                        value: widget.species.catalogVariant,
                      ),
                    FullWidthInfoEntry(
                      title: AppLocalizations.of(context).synonyms,
                      value: widget.species.synonyms?.join(", "),
                    ),
                    if (widget.showImageCredit && _hasImageCredit)
                      _buildImageCredit(context),
                  ],
          ),
          if (_hasSafetyInformation(widget.species.safety))
            InfoGroup(
              title: AppLocalizations.of(context).safetyAtHome,
              children: [
                _PlantSafetyCard(safety: widget.species.safety),
              ],
            ),
          if (_hasBenefitInformation(widget.species.benefits))
            InfoGroup(
              title: AppLocalizations.of(context).benefitsAtHome,
              children: [
                _PlantBenefitsCard(benefits: widget.species.benefits),
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
                    _buildAdditionalCareMetrics(context),
                    _buildCareDetails(context),
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

  Widget _buildCareDetails(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final String? careSource = _careSourceLabel(context);
    final bool hasDetails = widget.species.care.light != null ||
        widget.species.care.soilHumidity != null ||
        careSource != null ||
        widget.species.care.fieldProvenance.isNotEmpty ||
        widget.species.care.lastVerifiedAt != null;
    if (!hasDetails) return const SizedBox.shrink();

    return ExpansionTile(
      key: const Key('careDetailsExpansion'),
      initiallyExpanded: false,
      title: Text(localizations.careDetails),
      children: [
        SimpleInfoEntry(
          title: localizations.light,
          value: widget.species.care.light == null
              ? null
              : localizations.nOutOf(widget.species.care.light!, 10),
        ),
        SimpleInfoEntry(
          title: localizations.soilMoisture,
          value: widget.species.care.soilHumidity == null
              ? null
              : localizations.nOutOf(widget.species.care.soilHumidity!, 10),
        ),
        SimpleInfoEntry(
          title: localizations.careDataSource,
          value: careSource,
        ),
        ...widget.species.care.fieldProvenance.entries.map(
          (entry) => SimpleInfoEntry(
            title: _careFieldLabel(context, entry.key),
            value: _provenanceLabel(context, entry.value),
          ),
        ),
        SimpleInfoEntry(
          title: localizations.careDataLastVerified,
          value: widget.species.care.lastVerifiedAt == null
              ? null
              : MaterialLocalizations.of(context).formatMediumDate(
                  widget.species.care.lastVerifiedAt!.toLocal(),
                ),
        ),
      ],
    );
  }

  bool get _hasImageCredit =>
      (widget.species.imageAttribution?.trim().isNotEmpty ?? false) ||
      (widget.species.imageSource?.trim().isNotEmpty ?? false);

  Widget _buildImageCredit(BuildContext context) {
    final String attribution = widget.species.imageAttribution?.trim() ?? '';
    final String source = switch (widget.species.imageSource) {
      'INATURALIST' => 'iNaturalist',
      'FLORA_CODEX' => 'FloraCodex',
      final String value when value.isNotEmpty => value,
      _ => '',
    };
    final String license = widget.species.imageLicenseCode?.trim() ?? '';
    final RegExpMatch? creatorMatch = RegExp(
      r'\(c\)\s*([^,]+)',
      caseSensitive: false,
    ).firstMatch(attribution);
    final String creator = creatorMatch?.group(1)?.trim() ?? attribution;
    final String credit = [
      if (creator.isNotEmpty) '© $creator',
      if (license.isNotEmpty) license.toUpperCase(),
      if (creator.isEmpty && license.isEmpty) source,
    ].join(' · ');
    final String sourceUrl = widget.species.imageSourceUrl?.trim() ?? '';
    final Uri? sourceUri = sourceUrl.isEmpty ? null : Uri.tryParse(sourceUrl);

    return ListTile(
      key: const Key('imageCredit'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.photo_camera_outlined, size: 20),
      title: Text(credit),
      trailing:
          sourceUri == null ? null : const Icon(Icons.open_in_new, size: 18),
      onTap: sourceUri == null ? null : () => launchUrl(sourceUri),
    );
  }

  Widget _buildAdditionalCareMetrics(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final List<Widget> metrics = [];
    if (widget.species.care.humidity != null) {
      metrics.add(
        _CareMetricCard(
          icon: Icons.air_outlined,
          title: localizations.humidity,
          value: localizations.nOutOf(widget.species.care.humidity!, 10),
        ),
      );
    }
    if (widget.species.care.minTemp != null ||
        widget.species.care.maxTemp != null) {
      metrics.add(
        _CareMetricCard(
          icon: Icons.thermostat_outlined,
          title: _rangeTitle(
            localizations.minTemp,
            localizations.maxTemp,
            widget.species.care.minTemp,
            widget.species.care.maxTemp,
          ),
          value: _temperatureRange(context),
        ),
      );
    }
    if (widget.species.care.phMin != null ||
        widget.species.care.phMax != null) {
      metrics.add(
        _CareMetricCard(
          icon: Icons.science_outlined,
          title: _rangeTitle(
            localizations.minPh,
            localizations.maxPh,
            widget.species.care.phMin,
            widget.species.care.phMax,
          ),
          value: _phRange(context),
        ),
      );
    }
    if (metrics.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth >= 560
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map((metric) => SizedBox(width: width, child: metric))
                .toList(),
          ),
        );
      },
    );
  }

  String _rangeTitle(
    String minimumLabel,
    String maximumLabel,
    num? minimum,
    num? maximum,
  ) {
    if (minimum != null && maximum != null) {
      return '$minimumLabel / $maximumLabel';
    }
    return minimum != null ? minimumLabel : maximumLabel;
  }

  String _temperatureRange(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final List<String> values = [];
    if (widget.species.care.minTemp != null) {
      values.add(localizations.temp(widget.species.care.minTemp!));
    }
    if (widget.species.care.maxTemp != null) {
      values.add(localizations.temp(widget.species.care.maxTemp!));
    }
    return values.join(' – ');
  }

  String _phRange(BuildContext context) {
    final List<String> values = [];
    if (widget.species.care.phMin != null) {
      values.add(widget.species.care.phMin!.toString());
    }
    if (widget.species.care.phMax != null) {
      values.add(widget.species.care.phMax!.toString());
    }
    return values.join(' – ');
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
    if (widget.species.care.source == 'CURATED_CATALOG') {
      return AppLocalizations.of(context).careDataProvidedByCuratedCatalog;
    }
    if (widget.species.care.source == 'PERENUAL') {
      return AppLocalizations.of(context).careDataProvidedByPerenual;
    }
    if (widget.species.care.source == 'MULTIPLE') {
      return AppLocalizations.of(context).careDataProvidedByMultiple;
    }
    return widget.species.care.source;
  }

  String _careFieldLabel(BuildContext context, String field) {
    return switch (field) {
      'light' => AppLocalizations.of(context).sunlight,
      'humidity' => AppLocalizations.of(context).humidity,
      'soilHumidity' => AppLocalizations.of(context).soilMoisture,
      'minTemp' => AppLocalizations.of(context).minTemp,
      'maxTemp' => AppLocalizations.of(context).maxTemp,
      'phMin' => AppLocalizations.of(context).minPh,
      'phMax' => AppLocalizations.of(context).maxPh,
      _ => field,
    };
  }

  String _provenanceLabel(
    BuildContext context,
    CareFieldProvenanceDTO provenance,
  ) {
    final String source = _sourceName(context, provenance.source);
    if (provenance.confidence == null) return source;
    return AppLocalizations.of(context).careSourceWithConfidence(
      source,
      (provenance.confidence! * 100).round(),
    );
  }

  String _sourceName(BuildContext context, String? source) {
    return switch (source) {
      'TREFLE' => AppLocalizations.of(context).careDataProvidedByTrefle,
      'CURATED_CATALOG' =>
        AppLocalizations.of(context).careDataProvidedByCuratedCatalog,
      'PERENUAL' => AppLocalizations.of(context).careDataProvidedByPerenual,
      _ => source ?? AppLocalizations.of(context).noInfoAvailable,
    };
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

  bool _hasSafetyInformation(PlantSafetyInfoDTO safety) {
    return safety.humanStatus != 'UNKNOWN' ||
        safety.catStatus != 'UNKNOWN' ||
        safety.dogStatus != 'UNKNOWN' ||
        safety.summary?.trim().isNotEmpty == true ||
        safety.hazardousParts.isNotEmpty ||
        safety.sources.isNotEmpty;
  }

  bool _hasBenefitInformation(PlantBenefitInfoDTO benefits) {
    return benefits.entries.any(_shouldShowBenefitEntry) ||
        benefits.sources.isNotEmpty;
  }
}

class _PlantSafetyCard extends StatelessWidget {
  final PlantSafetyInfoDTO safety;

  const _PlantSafetyCard({required this.safety});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final List<({IconData icon, String label, String status})> statuses = [
      if (safety.humanStatus != 'UNKNOWN')
        (
          icon: Icons.person_outline,
          label: localizations.humanSafety,
          status: safety.humanStatus,
        ),
      if (safety.catStatus != 'UNKNOWN')
        (
          icon: Icons.pets_outlined,
          label: localizations.catSafety,
          status: safety.catStatus,
        ),
      if (safety.dogStatus != 'UNKNOWN')
        (
          icon: Icons.pets,
          label: localizations.dogSafety,
          status: safety.dogStatus,
        ),
    ];
    return Card(
      color: const Color(0xFF102B23),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (statuses.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final double tileWidth = constraints.maxWidth >= 520
                      ? (constraints.maxWidth - 16) / 3
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses
                        .map(
                          (status) => _SafetyStatusTile(
                            width: tileWidth,
                            icon: status.icon,
                            label: status.label,
                            status: status.status,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            if (statuses.isNotEmpty &&
                safety.summary?.trim().isNotEmpty == true)
              const SizedBox(height: 14),
            if (safety.summary?.trim().isNotEmpty == true)
              Text(
                safety.summary!,
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            if (safety.hazardousParts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                localizations.hazardousParts,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                safety.hazardousParts.join(' · '),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (safety.hasUrgentHazard) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  border: Border.all(color: const Color(0xFFFFA3A3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.safetyEmergencyTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizations.safetyEmergencyMessage,
                      style: const TextStyle(color: Colors.white, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
            if (safety.sources.isNotEmpty)
              _ReviewedSourcesExpansionTile<PlantSafetySourceDTO>(
                key: const Key('safetyReviewedSources'),
                title: localizations.safetySources,
                sources: safety.sources,
              ),
            if (safety.lastVerifiedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                localizations.safetyChecked(
                  MaterialLocalizations.of(context).formatMediumDate(
                    safety.lastVerifiedAt!.toLocal(),
                  ),
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlantBenefitsCard extends StatelessWidget {
  final PlantBenefitInfoDTO benefits;

  const _PlantBenefitsCard({required this.benefits});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final visibleEntries = benefits.entries.where(_shouldShowBenefitEntry);
    final grouped = <String, List<PlantBenefitEntryDTO>>{
      'HUMAN':
          visibleEntries.where((entry) => entry.audience == 'HUMAN').toList(),
      'PET': visibleEntries.where((entry) => entry.audience == 'PET').toList(),
    };
    return Card(
      color: const Color(0xFF172554),
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...grouped.entries
                .where((group) => group.value.isNotEmpty)
                .map((group) => _BenefitAudienceSection(
                      title: group.key == 'HUMAN'
                          ? localizations.humanBenefits
                          : localizations.petBenefits,
                      entries: group.value,
                    )),
            if (benefits.sources.isNotEmpty)
              _ReviewedSourcesExpansionTile<PlantBenefitSourceDTO>(
                key: const Key('benefitReviewedSources'),
                title: localizations.benefitSources,
                sources: benefits.sources,
              ),
            if (benefits.lastVerifiedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                localizations.benefitChecked(
                  MaterialLocalizations.of(context).formatMediumDate(
                    benefits.lastVerifiedAt!.toLocal(),
                  ),
                ),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              localizations.benefitDisclaimer,
              style: const TextStyle(
                color: Color(0xFFD1D5DB),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitAudienceSection extends StatelessWidget {
  final String title;
  final List<PlantBenefitEntryDTO> entries;

  const _BenefitAudienceSection({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isNoInformationBenefit(entry) &&
                        (entry.title.trim().isNotEmpty ||
                            entry.category.trim().isNotEmpty))
                      Text(
                        [
                          _categoryLabel(localizations, entry.category),
                          entry.title.trim(),
                        ].where((value) => value.isNotEmpty).join(' · '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (!_isNoInformationBenefit(entry) &&
                        entry.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.summary,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (entry.caution?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.caution!,
                        style:
                            const TextStyle(color: Colors.white60, height: 1.3),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _categoryLabel(AppLocalizations localizations, String category) {
    return switch (category) {
      'FOOD' => localizations.foodBenefitCategory,
      'ENRICHMENT' => localizations.enrichmentBenefitCategory,
      'MEDICINE' => localizations.medicineBenefitCategory,
      _ => category,
    };
  }
}

bool _shouldShowBenefitEntry(PlantBenefitEntryDTO entry) {
  if (!_isNoInformationBenefit(entry)) return true;

  // A food-related negative claim can still carry useful feeding or exposure
  // guidance. Keep the caution while hiding the empty benefit claim itself.
  return entry.category == 'FOOD' && entry.caution?.trim().isNotEmpty == true;
}

bool _isNoInformationBenefit(PlantBenefitEntryDTO entry) {
  final String text = '${entry.title} ${entry.summary}'.toLowerCase();
  if (text.contains('no reviewed') &&
      (text.contains('benefit') || text.contains('health'))) {
    return true;
  }
  if (text.contains('not a pet dietary supplement')) return true;

  if (entry.category == 'MEDICINE' &&
      (text.contains('no treatment claim') ||
          text.contains('not a medicine') ||
          text.contains('not a treatment') ||
          text.contains('does not recommend') ||
          text.contains('do not replace medical care'))) {
    return true;
  }
  return false;
}

class _ReviewedSourcesExpansionTile<T> extends StatelessWidget {
  final String title;
  final List<T> sources;

  const _ReviewedSourcesExpansionTile({
    super.key,
    required this.title,
    required this.sources,
  });

  String _sourceName(T source) {
    return switch (source) {
      PlantSafetySourceDTO value => value.name,
      PlantBenefitSourceDTO value => value.name,
      _ => '',
    };
  }

  String _sourceUrl(T source) {
    return switch (source) {
      PlantSafetySourceDTO value => value.url,
      PlantBenefitSourceDTO value => value.url,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      iconColor: Colors.white70,
      collapsedIconColor: Colors.white70,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sources.map((source) {
              final Uri? uri = Uri.tryParse(_sourceUrl(source));
              return TextButton.icon(
                onPressed: uri == null ? null : () => launchUrl(uri),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(_sourceName(source)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SafetyStatusTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String status;

  const _SafetyStatusTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final _SafetyStyle style = _style(context, status);
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.foreground.withOpacity(.65)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: style.foreground, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: style.foreground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  style.label,
                  style: TextStyle(color: style.foreground, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _SafetyStyle _style(BuildContext context, String status) {
    final localizations = AppLocalizations.of(context);
    return switch (status) {
      'NON_TOXIC' => _SafetyStyle(
          localizations.safetyNonToxic,
          const Color(0xFF064E3B),
          const Color(0xFFD1FAE5),
        ),
      'CAUTION' => _SafetyStyle(
          localizations.safetyCaution,
          const Color(0xFF713F12),
          const Color(0xFFFEF3C7),
        ),
      'TOXIC' => _SafetyStyle(
          localizations.safetyToxic,
          const Color(0xFF7C2D12),
          const Color(0xFFFFEDD5),
        ),
      'HIGHLY_TOXIC' => _SafetyStyle(
          localizations.safetyHighlyToxic,
          const Color(0xFF7F1D1D),
          const Color(0xFFFFE4E6),
        ),
      _ => _SafetyStyle(
          localizations.safetyUnknown,
          const Color(0xFF374151),
          const Color(0xFFF3F4F6),
        ),
    };
  }
}

class _SafetyStyle {
  final String label;
  final Color background;
  final Color foreground;

  const _SafetyStyle(this.label, this.background, this.foreground);
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guidance,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CareMetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromRGBO(24, 44, 37, 1),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: Colors.lightGreenAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
