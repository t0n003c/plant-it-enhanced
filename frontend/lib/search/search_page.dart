import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/app_layout.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/search/add_custom.dart';
import 'package:plant_it/search/guided_photo_sheet.dart';
import 'package:plant_it/search/photo_source_sheet.dart';
import 'package:plant_it/search/plant_search_repository.dart';
import 'package:plant_it/search/search_result.dart';

class SearchPage extends StatefulWidget {
  final Environment env;
  const SearchPage({
    super.key,
    required this.env,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const Duration _searchDelay = Duration(milliseconds: 400);
  static const int _minimumSearchLength = 2;
  final TextEditingController _searchController = TextEditingController();
  late final PlantSearchRepository _repository;
  List<SpeciesDTO> _result = [];
  Timer? _debounce;
  bool _loading = false;
  String? _errorMessage;
  int _requestSequence = 0;
  XFile? _identificationImage;
  bool _identificationMode = false;

  Future<void> _fetchAndSetResult(String searchTerm) async {
    final String normalizedTerm = searchTerm.trim();
    final int requestId = ++_requestSequence;
    if (normalizedTerm.length < _minimumSearchLength) {
      setState(() {
        _result = [];
        _loading = false;
        _errorMessage = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final Locale locale = Localizations.localeOf(context);
      final List<SpeciesDTO> result = await _repository.search(
        term: normalizedTerm,
        language: locale.languageCode,
        region: locale.countryCode,
      );
      if (!mounted || requestId != _requestSequence) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted || requestId != _requestSequence) return;
      widget.env.logger.error(e, st);
      setState(() {
        _result = [];
        _loading = false;
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  void _handleSearchChanged(String value) {
    _debounce?.cancel();
    _requestSequence++;
    final String normalizedTerm = value.trim();
    setState(() {
      _identificationMode = false;
      _identificationImage = null;
      _errorMessage = null;
      _loading = normalizedTerm.length >= _minimumSearchLength;
      if (normalizedTerm.length < _minimumSearchLength) {
        _result = [];
      }
    });
    if (normalizedTerm.length < _minimumSearchLength) return;
    _debounce = Timer(_searchDelay, () {
      _fetchAndSetResult(normalizedTerm);
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    final String normalizedTerm = value.trim();
    if (normalizedTerm.length < _minimumSearchLength) {
      _handleSearchChanged(normalizedTerm);
      return;
    }
    _fetchAndSetResult(normalizedTerm);
  }

  void _clearSearch() {
    _debounce?.cancel();
    _requestSequence++;
    _searchController.clear();
    setState(() {
      _result = [];
      _loading = false;
      _errorMessage = null;
      _identificationMode = false;
      _identificationImage = null;
    });
  }

  Future<void> _startGuidedIdentification(ImageSource source) async {
    Navigator.of(context).pop();
    final XFile? image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image == null || !mounted) return;
    final GuidedPhotoSelection? selection =
        await showModalBottomSheet<GuidedPhotoSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PhotoSourceSheet.backgroundColor,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => GuidedPhotoSheet(initialImage: image),
    );
    if (selection == null || !mounted) return;
    await _identifyPhotos(selection);
  }

  Future<void> _identifyPhotos(GuidedPhotoSelection selection) async {
    _debounce?.cancel();
    final int requestId = ++_requestSequence;
    final Locale locale = Localizations.localeOf(context);
    setState(() {
      _loading = true;
      _errorMessage = null;
      _identificationMode = true;
      _identificationImage = selection.images.first;
      _searchController.clear();
    });
    try {
      final List<SpeciesDTO> candidates = await _repository.identify(
        images: selection.images,
        organs: selection.organs,
        language: locale.languageCode,
      );
      if (!mounted || requestId != _requestSequence) return;
      setState(() {
        _result = candidates.take(3).toList(growable: false);
        if (_result.isEmpty) {
          _errorMessage = AppLocalizations.of(context).noIdentificationMatch;
        }
      });
    } catch (error, stackTrace) {
      if (!mounted || requestId != _requestSequence) return;
      widget.env.logger.error(error, stackTrace);
      setState(() {
        _result = [];
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && requestId == _requestSequence) {
        setState(() => _loading = false);
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: PhotoSourceSheet.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => PhotoSourceSheet(
        onCamera: () => _startGuidedIdentification(ImageSource.camera),
        onGallery: () => _startGuidedIdentification(ImageSource.gallery),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _repository = PlantSearchRepository(widget.env.http);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedTerm = _searchController.text.trim();
    final bool showSearchPrompt = !_identificationMode &&
        normalizedTerm.length < _minimumSearchLength &&
        !_loading;
    final bool showNoResults = !_identificationMode &&
        normalizedTerm.length >= _minimumSearchLength &&
        !_loading &&
        _errorMessage == null &&
        _result.isEmpty;
    final bool showCustomCard = !_identificationMode &&
        normalizedTerm.length >= _minimumSearchLength &&
        !_loading &&
        _errorMessage == null;
    final int cardCount = _result.length + (showCustomCard ? 1 : 0);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: AppContent(
            maxWidth: appReadableMaxWidth,
            child: AppPageHeader(
              icon: Icons.travel_explore_rounded,
              title: AppLocalizations.of(context).search,
              subtitle: AppLocalizations.of(context).searchNewGreenFriends,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: AppContent(
            maxWidth: appReadableMaxWidth,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final Widget searchField = TextField(
                      key: const ValueKey('plant-search-field'),
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context).searchNewGreenFriends,
                        prefixIcon: const Icon(Icons.search_outlined),
                        suffixIcon: normalizedTerm.isNotEmpty
                            ? IconButton(
                                key: const ValueKey('clear-plant-search'),
                                onPressed: _clearSearch,
                                tooltip: MaterialLocalizations.of(context)
                                    .closeButtonTooltip,
                                icon: const Icon(Icons.close_outlined),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _handleSearchChanged,
                      onSubmitted: _submitSearch,
                    );
                    final Widget photoButton = FilledButton.tonalIcon(
                      key: const ValueKey('identify-plant-by-photo'),
                      onPressed: _showPhotoOptions,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(AppLocalizations.of(context).identifyByPhoto),
                    );
                    if (constraints.maxWidth < 560) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 10),
                          photoButton,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 10),
                        photoButton,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        if (_loading)
          SliverToBoxAdapter(
            child: AppContent(
              maxWidth: appReadableMaxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 8),
                  Text(
                    _identificationMode
                        ? AppLocalizations.of(context).identifyingPlant
                        : AppLocalizations.of(context)
                            .searchingForPlant(normalizedTerm),
                    key: const ValueKey('plant-search-progress-label'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        if (_identificationMode && !_loading && _errorMessage == null)
          SliverToBoxAdapter(
            child: AppContent(
              maxWidth: appReadableMaxWidth,
              child: Text(
                AppLocalizations.of(context).identificationCandidates,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        if (_errorMessage != null)
          SliverToBoxAdapter(
            child: AppContent(
              maxWidth: appReadableMaxWidth,
              child: Card(
                child: AppEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: AppLocalizations.of(context).generalError,
                  message: _errorMessage,
                  action: normalizedTerm.length >= _minimumSearchLength
                      ? OutlinedButton.icon(
                          onPressed: () => _fetchAndSetResult(normalizedTerm),
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context).retry),
                        )
                      : null,
                ),
              ),
            ),
          ),
        if (showSearchPrompt)
          SliverToBoxAdapter(
            child: AppContent(
              maxWidth: appReadableMaxWidth,
              child: Card(
                child: AppEmptyState(
                  icon: Icons.local_florist_outlined,
                  title: AppLocalizations.of(context).plantSearchStartHint,
                ),
              ),
            ),
          ),
        if (showNoResults)
          SliverToBoxAdapter(
            child: AppContent(
              maxWidth: appReadableMaxWidth,
              child: Card(
                child: AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: AppLocalizations.of(context)
                      .noPlantSearchResults(normalizedTerm),
                ),
              ),
            ),
          ),
        if (_errorMessage == null && cardCount > 0)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _result.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: AppContent(
                        maxWidth: appReadableMaxWidth,
                        padding: EdgeInsets.zero,
                        child: AddCustomCard(
                          key: const ValueKey('add-custom-plant-result'),
                          env: widget.env,
                          species: normalizedTerm,
                          updateSpeciesLocally: (s) =>
                              _fetchAndSetResult(_searchController.text),
                        ),
                      ),
                    );
                  }
                  final SpeciesDTO species = _result[index];
                  final String resultKey = species.canonicalTaxonKey ??
                      species.externalId ??
                      species.scientificName;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: AppContent(
                      maxWidth: appReadableMaxWidth,
                      padding: EdgeInsets.zero,
                      child: SearchResultCard(
                        key: ValueKey('plant-search-result-$resultKey'),
                        species: species,
                        env: widget.env,
                        result: _result,
                        identificationImage:
                            _identificationMode ? _identificationImage : null,
                        updateSpeciesLocally: (s) =>
                            _fetchAndSetResult(_searchController.text),
                      ),
                    ),
                  );
                },
                childCount: cardCount,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
