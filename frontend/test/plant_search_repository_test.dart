import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/search/identification_context.dart';
import 'package:plant_it/search/plant_search_repository.dart';

void main() {
  test('decodes plant search results and sends locale context', () async {
    final _StubHttpClient client = _StubHttpClient(
      http.Response(
        '[{"id":1,"scientificName":"Monstera deliciosa","synonyms":[],"commonNames":[],"externalReferences":{},"plantCareInfo":{},"creator":"INATURALIST","searchMatchReason":"EXACT_COMMON_NAME","searchMatchedName":"Monstera","catalogTags":[]}]',
        200,
      ),
    );
    final PlantSearchRepository repository = PlantSearchRepository(client);

    final List<SpeciesDTO> result = await repository.search(
      term: 'monstera',
      language: 'en',
      region: 'US',
    );

    expect(result, hasLength(1));
    expect(result.single.scientificName, 'Monstera deliciosa');
    expect(result.single.searchMatchedName, 'Monstera');
    expect(client.lastUrl, contains('q=monstera'));
    expect(client.lastUrl, contains('locale=en'));
    expect(client.lastUrl, contains('region=US'));
  });

  test('rejects an incompatible plant result envelope', () async {
    final PlantSearchRepository repository = PlantSearchRepository(
      _StubHttpClient(http.Response('{"content":[]}', 200)),
    );

    expect(
      repository.search(term: 'rose', language: 'en'),
      throwsA(isA<Exception>()),
    );
  });

  test('passes opt-in field context to photo identification', () async {
    final _StubHttpClient client = _StubHttpClient(
      http.Response(
        '[{"scientificName":"Trillium grandiflorum","synonyms":[],"commonNames":[],"externalReferences":{},"plantCareInfo":{},"creator":"PLANTNET","catalogTags":[],"identificationProject":"k-northern-america"}]',
        200,
      ),
    );
    final PlantSearchRepository repository = PlantSearchRepository(client);
    final IdentificationContext context = IdentificationContext(
      latitude: 41.8781,
      longitude: -87.6298,
      observedAt: DateTime.utc(2026, 7, 18),
    );

    final List<SpeciesDTO> result = await repository.identify(
      images: <XFile>[
        XFile.fromData(Uint8List.fromList(<int>[1, 2, 3]), name: 'plant.jpg')
      ],
      organs: <String>['leaf'],
      language: 'en',
      context: context,
    );

    expect(result.single.identificationProject, 'k-northern-america');
    expect(client.lastContext, same(context));
  });
}

class _StubHttpClient extends AppHttpClient {
  final http.Response response;
  String? lastUrl;
  IdentificationContext? lastContext;

  _StubHttpClient(this.response);

  @override
  Future<http.Response> get(String url) async {
    lastUrl = url;
    return response;
  }

  @override
  Future<http.Response> identifyPlant(
    List<XFile> images,
    List<String> organs,
    String language,
  ) async {
    return response;
  }

  @override
  Future<http.Response> identifyPlantWithContext(
    List<XFile> images,
    List<String> organs,
    String language, {
    IdentificationContext? context,
  }) async {
    lastContext = context;
    return response;
  }
}
