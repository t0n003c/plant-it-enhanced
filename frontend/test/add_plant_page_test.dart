import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:plant_it/app_http_client.dart';
import 'package:plant_it/change_notifiers.dart';
import 'package:plant_it/dto/species_dto.dart';
import 'package:plant_it/environment.dart';
import 'package:plant_it/plant_add/add_plant_page.dart';
import 'package:plant_it/theme.dart';
import 'package:plant_it/toast/toast_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('photo identification uses common name and saves avatar photo',
      (tester) async {
    final _AddPlantHttpClient httpClient = _AddPlantHttpClient();
    final _RecordingToastManager toastManager = _RecordingToastManager();
    final Environment environment = await _environment(
      httpClient,
      toastManager,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<EventsNotifier>(
        create: (_) => EventsNotifier(),
        child: MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AddPlantPage(
            env: environment,
            species: _identifiedRose(),
            identificationImage: XFile.fromData(
              _pixel,
              name: 'identified.jpg',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(httpClient.uploadCount, 1);
    expect(httpClient.postedUrls, contains('image/plant/7/image-123'));
    expect(
      (httpClient.postedBodies.first['info']
          as Map<String, dynamic>)['currencySymbol'],
      '\$',
    );
    expect(environment.plants, hasLength(1));
    expect(environment.plants.single.info.personalName, 'Rose');
    expect(environment.plants.single.avatarImageId, 'image-123');
    expect(toastManager.successCount, 1);
    expect(tester.takeException(), isNull);
  });
}

Future<Environment> _environment(
  _AddPlantHttpClient httpClient,
  _RecordingToastManager toastManager,
) async {
  SharedPreferences.setMockInitialValues({});
  return Environment(
    prefs: await SharedPreferences.getInstance(),
    http: httpClient,
    backendVersion: '0.17.1',
    credentials: Credentials(
      username: 'gardener',
      email: 'garden@example.com',
    ),
    notificationDispatcher: const [],
    eventTypes: const [],
    plants: [],
    toastManager: toastManager,
  );
}

SpeciesDTO _identifiedRose() {
  return SpeciesDTO(
    id: 42,
    scientificName: 'Rosa rubiginosa',
    preferredCommonName: 'Rose',
    care: SpeciesCareInfoDTO(light: 6, soilHumidity: 6, allNull: false),
    creator: 'PLANTNET',
  );
}

class _AddPlantHttpClient extends AppHttpClient {
  final List<String> postedUrls = [];
  final List<Map<String, dynamic>> postedBodies = [];
  int uploadCount = 0;

  _AddPlantHttpClient() {
    backendUrl = 'http://localhost/api/';
    key = 'test-key';
  }

  @override
  Future<http.Response> get(String url) async {
    return http.Response('0', 200);
  }

  @override
  Future<http.Response> post(String url, Map<String, dynamic>? body) async {
    postedUrls.add(url);
    postedBodies.add(body ?? {});
    if (url == 'plant') {
      return http.Response(jsonEncode(_plantJson()), 200);
    }
    if (url.startsWith('image/plant/')) {
      return http.Response(
        jsonEncode(_plantJson(avatarImageId: 'image-123')),
        200,
      );
    }
    return http.Response('{}', 200);
  }

  @override
  Future<http.Response> uploadImage(XFile image, int plantId) async {
    uploadCount++;
    return http.Response(jsonEncode('image-123'), 200);
  }
}

Map<String, dynamic> _plantJson({String? avatarImageId}) {
  return {
    'id': 7,
    'info': {'personalName': 'Rose'},
    'botanicalInfoId': 42,
    'botanicalInfoSpecies': 'Rosa rubiginosa',
    if (avatarImageId != null) 'avatarImageId': avatarImageId,
    if (avatarImageId != null) 'avatarMode': 'SPECIFIED',
  };
}

class _RecordingToastManager implements ToastManager {
  int successCount = 0;

  @override
  void showToast(BuildContext context, ToastNotificationType type, String msg) {
    if (type == ToastNotificationType.success) successCount++;
  }
}

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
