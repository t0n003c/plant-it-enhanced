import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  static const double _contentMaxWidth = 720;
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
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: _constrainContent(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const ValueKey('identify-plant-by-photo'),
                    onPressed: _showPhotoOptions,
                    tooltip: AppLocalizations.of(context).identifyByPhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_loading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        if (_identificationMode && !_loading && _errorMessage == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                AppLocalizations.of(context).identificationCandidates,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        if (_errorMessage != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        if (showSearchPrompt)
          SliverToBoxAdapter(
            child: _SearchMessage(
              icon: Icons.local_florist_outlined,
              message: AppLocalizations.of(context).plantSearchStartHint,
            ),
          ),
        if (showNoResults)
          SliverToBoxAdapter(
            child: _SearchMessage(
              icon: Icons.search_off_outlined,
              message: AppLocalizations.of(context)
                  .noPlantSearchResults(normalizedTerm),
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
                      child: _constrainContent(
                        AddCustomCard(
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
                    child: _constrainContent(
                      SearchResultCard(
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

  Widget _constrainContent(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SearchMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF9BE7A1)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
