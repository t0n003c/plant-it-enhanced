import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiResponseException implements Exception {
  final String message;
  final int? statusCode;

  const ApiResponseException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiResponseDecoder {
  static const String incompatibleResponseMessage =
      'The server returned data this app version cannot read. '
      'Update or redeploy the server and web app together, then try again.';

  const ApiResponseDecoder();

  T decode<T>(
    http.Response response,
    T Function(Object? body) convert, {
    required String fallbackError,
  }) {
    final bool successful =
        response.statusCode >= 200 && response.statusCode < 300;
    final Object? body = _tryDecode(response);
    if (!successful) {
      throw ApiResponseException(
        _errorMessage(body) ?? fallbackError,
        statusCode: response.statusCode,
      );
    }
    try {
      return convert(body);
    } on TypeError catch (_) {
      throw ApiResponseException(
        incompatibleResponseMessage,
        statusCode: response.statusCode,
      );
    } on FormatException catch (_) {
      throw ApiResponseException(
        incompatibleResponseMessage,
        statusCode: response.statusCode,
      );
    }
  }

  Object? _tryDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (_) {
      return null;
    }
  }

  String? _errorMessage(Object? body) {
    if (body case final Map<Object?, Object?> errorBody) {
      final Object? message = errorBody['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
