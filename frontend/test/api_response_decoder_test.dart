import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plant_it/api/api_response_decoder.dart';

void main() {
  const ApiResponseDecoder decoder = ApiResponseDecoder();

  test('decodes a successful typed response', () {
    final List<String> result = decoder.decode(
      http.Response('["monstera", "pothos"]', 200),
      (body) => (body! as List<dynamic>).cast<String>(),
      fallbackError: 'Search failed',
    );

    expect(result, <String>['monstera', 'pothos']);
  });

  test('uses the server error message for a failed response', () {
    expect(
      () => decoder.decode(
        http.Response('{"message":"Provider quota exceeded"}', 429),
        (body) => body,
        fallbackError: 'Search failed',
      ),
      throwsA(
        isA<ApiResponseException>()
            .having((error) => error.statusCode, 'statusCode', 429)
            .having(
              (error) => error.message,
              'message',
              'Provider quota exceeded',
            ),
      ),
    );
  });

  test('turns an incompatible success body into an actionable message', () {
    expect(
      () => decoder.decode<List<Object?>>(
        http.Response('{"unexpected":true}', 200),
        (body) {
          if (body is! List<Object?>) {
            throw const FormatException('Expected list');
          }
          return body;
        },
        fallbackError: 'Search failed',
      ),
      throwsA(
        isA<ApiResponseException>().having(
          (error) => error.message,
          'message',
          ApiResponseDecoder.incompatibleResponseMessage,
        ),
      ),
    );
  });
}
