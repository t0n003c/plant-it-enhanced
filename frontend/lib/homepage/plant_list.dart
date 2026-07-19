import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/commons.dart';
import 'package:plant_it/dto/plant_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/plant_details/plant_details_page.dart';
import 'package:plant_it/theme.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlantList extends StatefulWidget {
  final Environment env;
  const PlantList({
    super.key,
    required this.env,
  });

  @override
  State<StatefulWidget> createState() => _PlantListState();
}

class _PlantListState extends State<PlantList> {
  final PageController _pageController =
      PageController(viewportFraction: .86, keepPage: true);
  final TextEditingController _searchController = TextEditingController();
  List<PlantDTO> _filteredPlants = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filteredPlants = List<PlantDTO>.from(widget.env.plants);
  }

  @override
  void didUpdateWidget(covariant PlantList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyFilter(_searchController.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesPlant(PlantDTO plant, String matchingTerm) {
    final String query = matchingTerm.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [plant.info.personalName, plant.species]
        .whereType<String>()
        .any((value) => value.toLowerCase().contains(query));
  }

  void _applyFilter(String value) {
    if (!mounted) return;
    setState(() {
      _filteredPlants = widget.env.plants
          .where((plant) => _matchesPlant(plant, value))
          .toList();
    });
    if (_pageController.hasClients && _filteredPlants.isNotEmpty) {
      _pageController.jumpToPage(0);
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _applyFilter('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: AppLocalizations.of(context).plants,
          subtitle:
              '${_filteredPlants.length} / ${widget.env.plants.length} ${AppLocalizations.of(context).plants.toLowerCase()}',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).searchInYourPlants,
              prefixIcon: const Icon(Icons.search_outlined),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      tooltip:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                      icon: const Icon(Icons.close_outlined),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {});
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 250),
                () => _applyFilter(value),
              );
            },
            onSubmitted: _applyFilter,
          ),
        ),
        if (_filteredPlants.isEmpty)
          Card(
            child: AppEmptyState(
              icon: widget.env.plants.isEmpty
                  ? Icons.local_florist_outlined
                  : Icons.search_off_outlined,
              title: widget.env.plants.isEmpty
                  ? AppLocalizations.of(context).noPlantsYet
                  : AppLocalizations.of(context).noPlantsMatch,
              message: widget.env.plants.isEmpty
                  ? AppLocalizations.of(context).noPlantsYetHint
                  : AppLocalizations.of(context).tryAnotherPlantSearch,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 720) {
                final int columns = constraints.maxWidth >= 980 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 4 / 3,
                  ),
                  itemCount: _filteredPlants.length,
                  itemBuilder: (context, index) =>
                      _buildPlantLink(_filteredPlants[index]),
                );
              }
              final double carouselHeight =
                  (constraints.maxWidth * .74).clamp(250.0, 350.0).toDouble();
              return Column(
                children: [
                  SizedBox(
                    height: carouselHeight,
                    child: PageView.builder(
                      itemCount: _filteredPlants.length,
                      controller: _pageController,
                      padEnds: false,
                      itemBuilder: (_, index) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildPlantLink(_filteredPlants[index]),
                      ),
                    ),
                  ),
                  if (_filteredPlants.length > 1) ...[
                    const SizedBox(height: 14),
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _filteredPlants.length,
                      effect: const ScrollingDotsEffect(
                        dotWidth: 7,
                        dotHeight: 7,
                        spacing: 7,
                        activeDotScale: 1.5,
                        activeDotColor: Color(0xFF6DD075),
                        dotColor: Color(0xFF547466),
                      ),
                      onDotClicked: (index) => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildPlantLink(PlantDTO plant) {
    return Semantics(
      button: true,
      label: plant.info.personalName ?? plant.species,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await goToPageSlidingUp(
              context,
              PlantDetailsPage(env: widget.env, plant: plant),
            );
            _applyFilter(_searchController.text);
          },
          child: PlantCard(plant: plant, http: widget.env.http),
        ),
      ),
    );
  }
}

class PlantCard extends StatelessWidget {
  final PlantDTO plant;
  final AppHttpClient http;

  const PlantCard({
    super.key,
    required this.plant,
    required this.http,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: CachedNetworkImage(
          imageUrl: "${http.backendUrl}image/content/${plant.avatarImageId}",
          httpHeaders: {
            if (http.key != null) "Key": http.key!,
          },
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
          fit: BoxFit.cover,
          placeholder: (context, url) => Skeletonizer(
            enabled: true,
            effect: skeletonizerEffect,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
          errorWidget: (context, url, error) => _withLabels(
            context,
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(36),
              child: Image.asset(
                'assets/images/no-image.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          imageBuilder: (context, imageProvider) {
            return _withLabels(
              context,
              DecoratedBox(
                decoration: BoxDecoration(
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _withLabels(BuildContext context, Widget background) {
    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 118,
            decoration: BoxDecoration(
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
          bottom: 14,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.info.personalName ?? plant.species ?? '',
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (plant.info.personalName != null && plant.species != null)
                Text(
                  plant.species!,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
