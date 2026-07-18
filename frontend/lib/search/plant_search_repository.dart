import 'package:image_picker/image_picker.dart';
import 'package:plant_it/api/api_response_decoder.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/search/identification_context.dart';

class PlantSearchRepository {
  final AppHttpClient _http;
  final ApiResponseDecoder _decoder;

  PlantSearchRepository(
    this._http, {
    ApiResponseDecoder decoder = const ApiResponseDecoder(),
  }) : _decoder = decoder;

  Future<List<SpeciesDTO>> search({
    required String term,
    required String language,
    String? region,
  }) async {
    final String normalizedTerm = term.trim();
    final String url = normalizedTerm.isEmpty
        ? 'botanical-info'
        : Uri(
            path: 'botanical-info/search',
            queryParameters: {
              'q': normalizedTerm,
              'locale': language,
              if (region != null && region.isNotEmpty) 'region': region,
            },
          ).toString();
    final response = await _http.get(url);
    return _decoder.decode(
      response,
      _speciesList,
      fallbackError: 'Plant search failed',
    );
  }

  Future<List<SpeciesDTO>> identify({
    required List<XFile> images,
    required List<String> organs,
    required String language,
    IdentificationContext? context,
  }) async {
    final response = await _http.identifyPlantWithContext(
      images,
      organs,
      language,
      context: context,
    );
    return _decoder.decode(
      response,
      _speciesList,
      fallbackError: 'Plant identification failed',
    );
  }

  List<SpeciesDTO> _speciesList(Object? body) {
    if (body is! List<Object?>) {
      throw const FormatException('Expected a list of plant results');
    }
    return body.map((candidate) {
      if (candidate is! Map<String, dynamic>) {
        throw const FormatException('Expected a plant result object');
      }
      return SpeciesDTO.fromJson(candidate);
    }).toList(growable: false);
  }
}
