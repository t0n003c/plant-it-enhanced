import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plant_it/search/add_custom.dart';
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
    final String url = normalizedTerm.isEmpty
        ? "botanical-info"
        : Uri(
            path: "botanical-info/search",
            queryParameters: {"q": normalizedTerm},
          ).toString();
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchNewGreenFriends,
                  prefixIcon: const Icon(Icons.search_outlined),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _debounce?.cancel();
                            _searchController.clear();
                            setState(() {});
                            _fetchAndSetResult("");
                          },
                          child: const Icon(Icons.close_outlined),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _requestSequence++;
                  setState(() {});
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(_searchDelay, () {
                    _fetchAndSetResult(value);
                  });
                },
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
                            updateSpeciesLocally: (s) =>
                                _fetchAndSetResult(_searchController.text),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
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
