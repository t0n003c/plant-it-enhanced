import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/search/add_custom.dart';
import 'package:plant_it/search/guided_photo_sheet.dart';
import 'package:plant_it/search/photo_source_sheet.dart';
import 'package:plant_it/search/search_result.dart';

class SeachPage extends StatefulWidget {
  final Environment env;
  const SeachPage({
    super.key,
    required this.env,
  });

  @override
  State<SeachPage> createState() => _SeachPageState();
}

class _SeachPageState extends State<SeachPage> {
  static const Duration _searchDelay = Duration(milliseconds: 1100);
  static const int _minimumSearchLength = 2;
  final TextEditingController _searchController = TextEditingController();
  final controller = PageController(viewportFraction: .8, keepPage: true);
  List<SpeciesDTO> _result = [];
  Timer? _debounce;
  bool _loading = true;
  String? _errorMessage;
  int _requestSequence = 0;
  XFile? _identificationImage;
  bool _identificationMode = false;

  Future<void> _fetchAndSetResult(String searchTerm) async {
    final String normalizedTerm = searchTerm.trim();
    final int requestId = ++_requestSequence;
    if (normalizedTerm.isNotEmpty &&
        normalizedTerm.length < _minimumSearchLength) {
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
    final String url;
    if (normalizedTerm.isEmpty) {
      url = "botanical-info";
    } else {
      final Locale locale = Localizations.localeOf(context);
      url = Uri(
        path: "botanical-info/search",
        queryParameters: {
          "q": normalizedTerm,
          "locale": locale.languageCode,
          if (locale.countryCode != null && locale.countryCode!.isNotEmpty)
            "region": locale.countryCode!,
        },
      ).toString();
    }
    try {
      final response = await widget.env.http.get(url);
      if (!mounted || requestId != _requestSequence) return;
      if (response.statusCode != 200) {
        final dynamic errorBody = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody is Map
            ? errorBody["message"] ?? "Plant search failed"
            : "Plant search failed");
      }
      final List<dynamic> responseBody =
          json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _result = responseBody.map((p) => SpeciesDTO.fromJson(p)).toList();
      });
    } catch (e, st) {
      if (!mounted || requestId != _requestSequence) return;
      widget.env.logger.error(e, st);
      setState(() {
        _result = [];
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted && requestId == _requestSequence) {
        setState(() {
          _loading = false;
        });
      }
    }
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
      final response = await widget.env.http.identifyPlant(
        selection.images,
        selection.organs,
        locale.languageCode,
      );
      if (!mounted || requestId != _requestSequence) return;
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        throw Exception(
          body is Map
              ? body['message'] ?? 'Plant identification failed'
              : 'Plant identification failed',
        );
      }
      setState(() {
        _result = (body as List<dynamic>)
            .map((candidate) =>
                SpeciesDTO.fromJson(candidate as Map<String, dynamic>))
            .take(3)
            .toList();
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
    _fetchAndSetResult("");
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context).searchNewGreenFriends,
                        prefixIcon: const Icon(Icons.search_outlined),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _debounce?.cancel();
                                  _searchController.clear();
                                  setState(() {
                                    _identificationMode = false;
                                    _identificationImage = null;
                                  });
                                  _fetchAndSetResult("");
                                },
                                child: const Icon(Icons.close_outlined),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _requestSequence++;
                        setState(() {
                          _identificationMode = false;
                          _identificationImage = null;
                        });
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(_searchDelay, () {
                          _fetchAndSetResult(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _showPhotoOptions,
                    tooltip: AppLocalizations.of(context).identifyByPhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                ],
              ),
            ),
            if (_identificationMode && !_loading && _errorMessage == null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  AppLocalizations.of(context).identificationCandidates,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            if (_loading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(35),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(35),
                child: Column(
                  children: [
                    ..._result.map(
                      (r) => Column(
                        children: [
                          SearchResultCard(
                            species: r,
                            env: widget.env,
                            result: _result,
                            identificationImage: _identificationMode
                                ? _identificationImage
                                : null,
                            updateSpeciesLocally: (s) =>
                                _fetchAndSetResult(_searchController.text),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                    if (!_identificationMode)
                      AddCustomCard(
                        env: widget.env,
                        species: _searchController.text,
                        updateSpeciesLocally: (s) =>
                            _fetchAndSetResult(_searchController.text),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
