import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
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
      PageController(viewportFraction: .8, keepPage: true);
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
    final screenSize = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              children: [
                Icon(
                  widget.env.plants.isEmpty
                      ? Icons.local_florist_outlined
                      : Icons.search_off_outlined,
                  size: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.env.plants.isEmpty
                      ? AppLocalizations.of(context).noPlantsYet
                      : AppLocalizations.of(context).noPlantsMatch,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  widget.env.plants.isEmpty
                      ? AppLocalizations.of(context).noPlantsYetHint
                      : AppLocalizations.of(context).tryAnotherPlantSearch,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: min(screenSize.width, maxWidth) *
                .7, // height: screenSize.width * .8 // screenSize.height * .55
            child: PageView.builder(
              itemCount: _filteredPlants.length,
              controller: _pageController,
              itemBuilder: (_, index) {
                final PlantDTO plant = _filteredPlants[index];
                return Semantics(
                  button: true,
                  label: plant.info.personalName ?? plant.species,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await goToPageSlidingUp(
                        context,
                        PlantDetailsPage(
                          env: widget.env,
                          plant: plant,
                        ),
                      );
                      _applyFilter(_searchController.text);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: PlantCard(
                        plant: plant,
                        http: widget.env.http,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (_filteredPlants.isNotEmpty)
          SmoothPageIndicator(
            controller: _pageController,
            count: _filteredPlants.length,
            effect: const ScrollingDotsEffect(
              dotWidth: 5.0,
              dotHeight: 5.0,
              activeDotScale: 2,
              activeDotColor: Color(
                0xFF6DD075,
              ),
            ),
            onDotClicked: (index) => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.ease,
            ),
          )
      ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
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
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
          );
        },
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
            height: 80, // Adjust the height as needed
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
          bottom: 10,
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.info.personalName ?? '',
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                plant.species ?? '',
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
