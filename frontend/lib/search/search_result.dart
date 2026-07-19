import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/plant_add/add_plant_page.dart';
import 'package:plant_it/search/search_result_photo.dart';
import 'package:plant_it/search/species_details_page.dart';
import 'package:plant_it/search/tag.dart';
import 'package:plant_it/species_image_url.dart';

class SearchResultCard extends StatefulWidget {
  final SpeciesDTO species;
  final Environment env;
  final List<SpeciesDTO> result;
  final Function(SpeciesDTO) updateSpeciesLocally;
  final XFile? identificationImage;

  const SearchResultCard({
    super.key,
    required this.species,
    required this.env,
    required this.result,
    required this.updateSpeciesLocally,
    this.identificationImage,
  });

  @override
  State<SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<SearchResultCard> {
  static const AssetImage _missingImage =
      AssetImage('assets/images/no-image.png');

  Future<Uint8List>? _identificationImageBytes;

  String? get _url =>
      resolveSpeciesImageUrl(widget.species, widget.env.http.backendUrl);

  @override
  void initState() {
    super.initState();
    if (widget.identificationImage != null) {
      _identificationImageBytes = widget.identificationImage!.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_identificationImageBytes != null) {
      return FutureBuilder<Uint8List>(
        future: _identificationImageBytes,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildResultCard(
              context,
              imageProvider: _missingImage,
              loading: true,
            );
          }
          return _buildResultCard(
            context,
            imageProvider: MemoryImage(snapshot.data!),
            showAddAction: true,
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: _url ?? missingSpeciesImageUrl(widget.env.http.backendUrl),
      httpHeaders: {
        'Key': widget.env.http.key!,
      },
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 80),
      placeholder: (context, url) => _buildResultCard(
        context,
        imageProvider: _missingImage,
        loading: true,
      ),
      errorWidget: (context, url, error) => _buildResultCard(
        context,
        imageProvider: _missingImage,
      ),
      imageBuilder: (context, imageProvider) => _buildResultCard(
        context,
        imageProvider: imageProvider,
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required ImageProvider<Object> imageProvider,
    bool loading = false,
    bool showAddAction = false,
  }) {
    final String photoLabel = _displayName(context);
    return Material(
      color: const Color(0xFF182C25),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SearchResultPhotoFrame(
              imageProvider: imageProvider,
              semanticLabel: photoLabel,
              loading: loading,
              overlay: showAddAction
                  ? Positioned(
                      top: 12,
                      right: 12,
                      child: FilledButton.icon(
                        key: const Key('addIdentificationCandidateAction'),
                        onPressed: () => _openAddPlant(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC7F9CC),
                          foregroundColor: const Color(0xFF10231C),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context).addPlant),
                      ),
                    )
                  : null,
            ),
            _buildPlantSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantSummary(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final String? commonName = widget.species.searchDisplayCommonNameFor(
      locale.languageCode,
      region: locale.countryCode,
    );
    final bool hasCommonName = commonName != null && commonName.isNotEmpty;
    final List<Widget> tags = _buildTags(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty) ...[
            Wrap(spacing: 6, runSpacing: 6, children: tags),
            const SizedBox(height: 10),
          ],
          Text(
            hasCommonName ? commonName : widget.species.scientificName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (hasCommonName) ...[
            const SizedBox(height: 2),
            Text(
              widget.species.scientificName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB7C9C0),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.species.family ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF9FB2A9)),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('open-plant-details'),
                onPressed: () => _openDetails(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC7F9CC),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(AppLocalizations.of(context).details),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTags(BuildContext context) {
    final List<Widget> tags = [];
    if (widget.species.creator == 'USER') {
      tags.add(
        TagChip(tag: AppLocalizations.of(context).custom.toUpperCase()),
      );
    }
    if (widget.species.identificationConfidence != null) {
      tags.add(
        TagChip(
          tag:
              '${widget.species.identificationProvider ?? 'AI'} ${(widget.species.identificationConfidence! * 100).round()}%',
        ),
      );
    }
    if (widget.species.identificationProject != null) {
      tags.add(
        TagChip(
          tag: AppLocalizations.of(context).identificationRegionalFlora(
            widget.species.identificationProjectTitle ??
                widget.species.identificationProject!,
          ),
        ),
      );
    }
    if (widget.species.searchMatchReason != null &&
        widget.species.searchMatchConfidence != null) {
      tags.add(
        TagChip(
          tag: AppLocalizations.of(context).searchMatchLabel(
            _searchMatchReason(context, widget.species.searchMatchReason!),
            (widget.species.searchMatchConfidence! * 100).round(),
          ),
        ),
      );
    }
    if (widget.species.catalogTags.contains('NORTH_AMERICAN_TRAIL')) {
      tags.add(TagChip(tag: AppLocalizations.of(context).trailPlant));
    }
    if (widget.species.catalogTags.contains('CONTACT_HAZARD')) {
      tags.add(
        TagChip(
          tag: AppLocalizations.of(context).avoidPlantContact,
          backgroundColor: const Color(0xFFFFD166),
          foregroundColor: const Color(0xFF2B2100),
        ),
      );
    }
    final Widget? safetyTag = _buildSafetyTag(context);
    if (safetyTag != null) tags.add(safetyTag);
    return tags;
  }

  Widget? _buildSafetyTag(BuildContext context) {
    if (!widget.species.safety.reviewed) return null;
    const Map<String, int> severity = {
      'UNKNOWN': 0,
      'NON_TOXIC': 1,
      'CAUTION': 2,
      'TOXIC': 3,
      'HIGHLY_TOXIC': 4,
    };
    final List<String> statuses = [
      widget.species.safety.humanStatus,
      widget.species.safety.catStatus,
      widget.species.safety.dogStatus,
    ];
    final String status = statuses.reduce(
      (current, candidate) =>
          (severity[candidate] ?? 0) > (severity[current] ?? 0)
              ? candidate
              : current,
    );
    if (status == 'UNKNOWN' ||
        (status == 'NON_TOXIC' &&
            !statuses.every((value) => value == 'NON_TOXIC'))) {
      return null;
    }

    final String statusLabel = switch (status) {
      'NON_TOXIC' => AppLocalizations.of(context).safetyNonToxic,
      'CAUTION' => AppLocalizations.of(context).safetyCaution,
      'TOXIC' => AppLocalizations.of(context).safetyToxic,
      'HIGHLY_TOXIC' => AppLocalizations.of(context).safetyHighlyToxic,
      _ => AppLocalizations.of(context).safetyUnknown,
    };
    final (Color, Color) colors = switch (status) {
      'HIGHLY_TOXIC' || 'TOXIC' => (
          const Color(0xFFFFDAD6),
          const Color(0xFF410002)
        ),
      'CAUTION' => (const Color(0xFFFFE08A), const Color(0xFF332600)),
      _ => (const Color(0xFFC7F9CC), const Color(0xFF10231C)),
    };
    return TagChip(
      tag: '${AppLocalizations.of(context).safetyAtHome}: $statusLabel',
      backgroundColor: colors.$1,
      foregroundColor: colors.$2,
    );
  }

  String _displayName(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    return widget.species.searchDisplayCommonNameFor(
          locale.languageCode,
          region: locale.countryCode,
        ) ??
        widget.species.scientificName;
  }

  String _searchMatchReason(BuildContext context, String reason) {
    return switch (reason) {
      'EXACT_COMMON_NAME' =>
        AppLocalizations.of(context).searchMatchExactCommonName,
      'COMMON_NAME_PREFIX' =>
        AppLocalizations.of(context).searchMatchCommonNamePrefix,
      'COMMON_NAME_KEYWORDS' =>
        AppLocalizations.of(context).searchMatchCommonNameKeywords,
      'COMMON_NAME_TYPO' =>
        AppLocalizations.of(context).searchMatchCommonNameTypo,
      'SCIENTIFIC_NAME' =>
        AppLocalizations.of(context).searchMatchScientificName,
      'SCIENTIFIC_SYNONYM' =>
        AppLocalizations.of(context).searchMatchScientificSynonym,
      _ => AppLocalizations.of(context).searchMatchRelatedName,
    };
  }

  void _openDetails(BuildContext context) {
    goToPageSlidingUp(
      context,
      SpeciesDetailsPage(
        species: widget.species,
        env: widget.env,
        updateSpeciesLocally: widget.updateSpeciesLocally,
        identificationImage: widget.identificationImage,
      ),
    );
  }

  Future<void> _openAddPlant(BuildContext context) async {
    final dynamic speciesCreated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPlantPage(
          env: widget.env,
          species: widget.species,
          identificationImage: widget.identificationImage,
        ),
      ),
    );
    if (speciesCreated is SpeciesDTO) {
      widget.updateSpeciesLocally(speciesCreated);
    }
  }
}
