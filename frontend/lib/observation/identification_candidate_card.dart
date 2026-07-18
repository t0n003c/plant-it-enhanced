import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/species_image_url.dart';
import 'package:url_launcher/url_launcher.dart';

class IdentificationCandidateCard extends StatelessWidget {
  final SpeciesDTO candidate;
  final Environment env;
  final int rank;
  final bool selected;
  final ValueChanged<SpeciesDTO> onSelected;

  const IdentificationCandidateCard({
    super.key,
    required this.candidate,
    required this.env,
    required this.rank,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final String commonName = candidate.preferredCommonNameFor(
          locale.languageCode,
          region: locale.countryCode,
        ) ??
        candidate.scientificName;
    final bool contactHazard = candidate.catalogTags.contains(
      'CONTACT_HAZARD',
    );
    final bool hasContextAdjustment = candidate.identificationEvidence.any(
          (evidence) => evidence.adjustment > 0,
        ) ||
        (candidate.contextualIdentificationScore != null &&
            candidate.identificationConfidence != null &&
            (candidate.contextualIdentificationScore! -
                        candidate.identificationConfidence!)
                    .abs() >
                .0001);
    return Semantics(
      selected: selected,
      button: true,
      child: Card(
        key: ValueKey<String>(
          'identification-candidate-${candidate.scientificName}',
        ),
        color: selected ? const Color(0xFF315D4E) : const Color(0xFF182C25),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(candidate),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _thumbnail(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).candidateRank(rank),
                            style: const TextStyle(
                              color: Color(0xFF9BE59F),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            commonName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (commonName != candidate.scientificName)
                            Text(
                              candidate.scientificName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (candidate.family?.isNotEmpty == true)
                            Text(
                              candidate.family!,
                              style: const TextStyle(color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                    Radio<bool>(
                      value: true,
                      groupValue: selected,
                      activeColor: const Color(0xFFC7F9CC),
                      onChanged: (_) => onSelected(candidate),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (candidate.identificationConfidence != null)
                      _scoreChip(
                        AppLocalizations.of(context).providerPhotoScore(
                          (candidate.identificationConfidence! * 100).round(),
                        ),
                        const Color(0xFF27483D),
                      ),
                    if (candidate.contextualIdentificationScore != null &&
                        (candidate.identificationConfidence == null ||
                            hasContextAdjustment))
                      _scoreChip(
                        AppLocalizations.of(context).contextRankScore(
                          (candidate.contextualIdentificationScore! * 100)
                              .round(),
                        ),
                        const Color(0xFF3E6658),
                      ),
                    if (candidate.establishmentMeans?.isNotEmpty == true)
                      _scoreChip(
                        _establishmentLabel(context),
                        const Color(0xFF27483D),
                      ),
                  ],
                ),
                if (candidate.identificationEvidence.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...candidate.identificationEvidence.map(
                    (evidence) => _evidenceRow(context, evidence),
                  ),
                ],
                if (contactHazard) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166).withOpacity(.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD166)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFFD166),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)
                                .contactHazardCompareHint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final String? url = resolveSpeciesImageUrl(candidate, env.http.backendUrl);
    if (url == null) {
      return _imageFallback(Icons.local_florist_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: {
          if (env.http.key != null) 'Key': env.http.key!,
          if (env.http.jwt != null) 'Authorization': 'Bearer ${env.http.jwt}',
        },
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _imageFallback(
          Icons.image_not_supported_outlined,
        ),
      ),
    );
  }

  Widget _imageFallback(IconData icon) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF27483D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white70),
    );
  }

  Widget _scoreChip(String label, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _evidenceRow(
    BuildContext context,
    IdentificationEvidenceDTO evidence,
  ) {
    final String label = switch (evidence.code) {
      'REGIONAL_FLORA' => AppLocalizations.of(context)
          .regionalFloraEvidence(evidence.detail ?? evidence.source),
      'NEARBY_SEASONAL_OCCURRENCES' => AppLocalizations.of(context)
          .nearbySeasonalEvidence(evidence.observationCount ?? 0),
      'HABITAT_RECORDED' => AppLocalizations.of(context)
          .habitatRecordedEvidence(evidence.detail ?? ''),
      'ELEVATION_RECORDED' => AppLocalizations.of(context)
          .elevationRecordedEvidence(evidence.detail ?? ''),
      _ => evidence.detail ?? evidence.source,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            evidence.adjustment > 0
                ? Icons.trending_up_outlined
                : Icons.info_outline,
            size: 18,
            color: evidence.adjustment > 0
                ? const Color(0xFF9BE59F)
                : Colors.white70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, height: 1.3),
            ),
          ),
          if (evidence.sourceReference?.isNotEmpty == true)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)
                  .viewEvidenceSource(evidence.source),
              onPressed: () => launchUrl(
                Uri.parse(evidence.sourceReference!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
            ),
        ],
      ),
    );
  }

  String _establishmentLabel(BuildContext context) {
    final String status = switch (candidate.establishmentMeans) {
      'native' => AppLocalizations.of(context).nativeStatus,
      'introduced' => AppLocalizations.of(context).introducedStatus,
      'endemic' => AppLocalizations.of(context).endemicStatus,
      _ => candidate.establishmentMeans!,
    };
    final String? place = candidate.establishmentPlace;
    return place == null || place.isEmpty
        ? status
        : AppLocalizations.of(context).statusInPlace(status, place);
  }
}
