import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/plant_add/add_plant_page.dart';
import 'package:plant_it/search/species_details_page.dart';
import 'package:plant_it/search/tag.dart';
import 'package:plant_it/species_image_url.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/theme.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  Future<Uint8List>? _identificationImageBytes;

  String? get _url =>
      resolveSpeciesImageUrl(widget.species, widget.env.http.backendUrl);

  Widget _buildPlantLabels(BuildContext context) {
    final Locale locale = Localizations.localeOf(context);
    final String? commonName = widget.species.searchDisplayCommonNameFor(
      locale.languageCode,
      region: locale.countryCode,
    );
    final bool hasCommonName = commonName != null && commonName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.species.creator == "USER")
          TagChip(
            tag: AppLocalizations.of(context).custom.toUpperCase(),
          ),
        if (widget.species.identificationConfidence != null)
          TagChip(
            tag:
                '${widget.species.identificationProvider ?? 'AI'} ${(widget.species.identificationConfidence! * 100).round()}%',
          ),
        if (widget.species.identificationProject != null)
          TagChip(
            tag: AppLocalizations.of(context).identificationRegionalFlora(
              widget.species.identificationProjectTitle ??
                  widget.species.identificationProject!,
            ),
          ),
        if (widget.species.searchMatchReason != null &&
            widget.species.searchMatchConfidence != null)
          TagChip(
            tag: AppLocalizations.of(context).searchMatchLabel(
              _searchMatchReason(context, widget.species.searchMatchReason!),
              (widget.species.searchMatchConfidence! * 100).round(),
            ),
          ),
        if (widget.species.catalogTags.contains('NORTH_AMERICAN_TRAIL'))
          TagChip(tag: AppLocalizations.of(context).trailPlant),
        if (widget.species.catalogTags.contains('CONTACT_HAZARD'))
          TagChip(
            tag: AppLocalizations.of(context).avoidPlantContact,
            backgroundColor: const Color(0xFFFFD166),
            foregroundColor: const Color(0xFF2B2100),
          ),
        Text(
          hasCommonName ? commonName : widget.species.scientificName,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        if (hasCommonName)
          Text(
            widget.species.scientificName,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (widget.species.family != null)
          Text(
            widget.species.family!,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
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
            return const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildLocalImageCard(context, snapshot.data!);
        },
      );
    }
    return CachedNetworkImage(
      imageUrl: _url ?? missingSpeciesImageUrl(widget.env.http.backendUrl),
      httpHeaders: {
        "Key": widget.env.http.key!,
      },
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 80),
      placeholder: (context, url) => Stack(
        children: [
          Skeletonizer(
            effect: skeletonizerEffect,
            enabled: true,
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * .4,
                maxWidth: MediaQuery.of(context).size.height * .4,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage("assets/images/no-image.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: _buildPlantLabels(context),
          ),
        ],
      ),
      errorWidget: (context, url, error) {
        return GestureDetector(
          onTap: () => goToPageSlidingUp(
            context,
            SpeciesDetailsPage(
              species: widget.species,
              env: widget.env,
              updateSpeciesLocally: widget.updateSpeciesLocally,
              identificationImage: widget.identificationImage,
            ),
          ),
          child: Stack(
            children: [
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .4,
                  minHeight: MediaQuery.of(context).size.height * .4,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(24, 44, 37, 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(100),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: AssetImage("assets/images/no-image.png"),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: _buildPlantLabels(context),
              ),
            ],
          ),
        );
      },
      imageBuilder: (context, imageProvider) {
        return GestureDetector(
          onTap: () => goToPageSlidingUp(
            context,
            SpeciesDetailsPage(
              species: widget.species,
              env: widget.env,
              updateSpeciesLocally: widget.updateSpeciesLocally,
              identificationImage: widget.identificationImage,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:
                      _url == null ? const Color.fromRGBO(24, 44, 37, 1) : null,
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .4,
                  minHeight: MediaQuery.of(context).size.height * .4,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: EdgeInsets.all(_url == null ? 100 : 0),
                    child: Container(
                      padding: EdgeInsets.all(_url == null ? 100 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: _url == null ? BoxFit.contain : BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Add a gradient overlay to the bottom
              if (_url != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80, // Adjust the height as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(
                            10), // Match the container's borderRadius
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: _buildPlantLabels(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocalImageCard(BuildContext context, Uint8List imageBytes) {
    return GestureDetector(
      onTap: () => goToPageSlidingUp(
        context,
        SpeciesDetailsPage(
          species: widget.species,
          env: widget.env,
          updateSpeciesLocally: widget.updateSpeciesLocally,
          identificationImage: widget.identificationImage,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(imageBytes, fit: BoxFit.cover),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: _buildPlantLabels(context),
              ),
              Positioned(
                top: 10,
                right: 10,
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
              ),
            ],
          ),
        ),
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
