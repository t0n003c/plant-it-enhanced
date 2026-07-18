import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AppHttpClient {
  late final http.Client _inner;
  String? backendUrl;
  String? key;
  String? jwt;

  AppHttpClient() {
    _inner = http.Client();
  }

  Future<http.Response> get(String url) async {
    final modifiedUrl = _prependBackendURL(url);
    final request = http.Request('GET', modifiedUrl);
    request.headers['Content-type'] = 'application/json';
    request.headers['Accept'] = '*/*';
    if (key != null) {
      request.headers['Key'] = key!;
    }
    if (jwt != null) {
      request.headers['Authorization'] = "Bearer $jwt";
    }
    return await _inner.send(request).then(http.Response.fromStream);
  }

  Future<http.Response> getNoAuth(String url) async {
    final modifiedUrl = _prependBackendURL(url);
    final request = http.Request('GET', modifiedUrl);
    request.headers['Content-type'] = 'application/json';
    request.headers['Accept'] = '*/*';
    return await _inner.send(request).then(http.Response.fromStream);
  }

  Future<http.Response> post(String url, Map<String, dynamic>? body) async {
    final modifiedUrl = _prependBackendURL(url);
    final request = http.Request('POST', modifiedUrl);
    request.headers['Content-type'] = 'application/json';
    request.headers['Accept'] = '*/*';
    if (key != null) {
      request.headers['Key'] = key!;
    }
    if (jwt != null) {
      request.headers['Authorization'] = "Bearer $jwt";
    }
    request.body = jsonEncode(body);
    return _inner.send(request).then(http.Response.fromStream);
  }

  Future<http.Response> putList(String url, List<dynamic> body) async {
    final modifiedUrl = _prependBackendURL(url);
    final request = http.Request('PUT', modifiedUrl);
    request.headers['Content-type'] = 'application/json';
    request.headers['Accept'] = '*/*';
    if (key != null) {
      request.headers['Key'] = key!;
    }
    if (jwt != null) {
      request.headers['Authorization'] = "Bearer $jwt";
    }
    request.body = jsonEncode(body);
    return _inner.send(request).then(http.Response.fromStream);
  }

  Future<http.Response> put(String url, Map<String, dynamic>? body) async {
    final modifiedUrl = _prependBackendURL(url);
    final request = http.Request('PUT', modifiedUrl);
    request.headers['Content-type'] = 'application/json';
    request.headers['Accept'] = '*/*';
    if (key != null) {
      request.headers['Key'] = key!;
    }
    if (jwt != null) {
      request.headers['Authorization'] = "Bearer $jwt";
    }
    request.body = jsonEncode(body);
    return await _inner.send(request).then(http.Response.fromStream);
  }

  Future<http.Response> delete(String url) async {
    final modifiedUrl = _prependBackendURL(url);
    final request = http.Request('DELETE', modifiedUrl);
    request.headers['Content-type'] = 'application/json';
    request.headers['Accept'] = '*/*';
    if (key != null) {
      request.headers['Key'] = key!;
    }
    if (jwt != null) {
      request.headers['Authorization'] = "Bearer $jwt";
    }
    return await _inner.send(request).then(http.Response.fromStream);
  }

  MediaType _getMediaType(String imageName) {
    final String extension = imageName.split('.').last.toLowerCase();
    if (extension == 'jpg' || extension == 'jpeg') {
      return MediaType('image', 'jpeg');
    }
    return MediaType('image', extension);
  }

  Future<http.Response> identifyPlant(
    List<XFile> images,
    List<String> organs,
    String language,
  ) async {
    if (images.isEmpty || images.length != organs.length) {
      throw ArgumentError('Identification images and organ labels must match');
    }
    final uri = _prependBackendURL('plant-identification').replace(
      queryParameters: {
        'language': language,
      },
    );
    final request = http.MultipartRequest('POST', uri);
    for (int index = 0; index < images.length; index++) {
      final XFile image = images[index];
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          await image.readAsBytes(),
          filename: image.name,
          contentType: _getMediaType(image.name),
        ),
      );
      request.files.add(http.MultipartFile.fromString('organs', organs[index]));
    }
    if (key != null) request.headers['Key'] = key!;
    if (jwt != null) request.headers['Authorization'] = 'Bearer $jwt';
    return http.Response.fromStream(await request.send());
  }

  Future<http.Response> uploadImage(XFile image, int plantId) async {
    final imageBytes = await image.readAsBytes();
    final request = http.MultipartRequest(
      'POST',
      _prependBackendURL('image/entity/$plantId'),
    );
    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes,
          filename: image.name, contentType: _getMediaType(image.name)),
    );
    if (key != null) {
      request.headers['Key'] = key!;
    }
    if (jwt != null) {
      request.headers['Authorization'] = "Bearer $jwt";
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return response;
  }

  Future<http.Response> uploadObservationImage(
    XFile image,
    int observationId, {
    String? description,
  }) async {
    final imageBytes = await image.readAsBytes();
    final uri = _prependBackendURL('observation/$observationId/image').replace(
      queryParameters: {
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: image.name,
        contentType: _getMediaType(image.name),
      ),
    );
    if (key != null) request.headers['Key'] = key!;
    if (jwt != null) request.headers['Authorization'] = 'Bearer $jwt';
    return http.Response.fromStream(await request.send());
  }

  void close() {
    _inner.close();
  }

  Uri _prependBackendURL(String url) {
    String urlString = "${backendUrl ?? ""}$url";
    return Uri.parse(urlString);
  }
}
