import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper', () {
    group('map', () {
      test('returns AuthError unchanged', () {
        const error = NetworkError();
        final result = ErrorMapper.map(error, StackTrace.current);
        expect(result, same(error));
      });

      test('maps connection error to NetworkError', () {
        final error = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/test'),
        );
        final result = ErrorMapper.map(error, StackTrace.current);
        expect(result, isA<NetworkError>());
      });

      test('maps connection timeout to NetworkError', () {
        final error = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );
        final result = ErrorMapper.map(error, StackTrace.current);
        expect(result, isA<NetworkError>());
      });

      test('maps DioException with response to response error', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/test'),
          ),
        );
        final result = ErrorMapper.map(error, StackTrace.current);
        expect(result, isA<InvalidCredentials>());
      });

      test('maps unknown error to UnknownError', () {
        final result = ErrorMapper.map(
          Exception('Something broke'),
          StackTrace.current,
        );
        expect(result, isA<UnknownError>());
        expect(result.message, contains('Something broke'));
      });
    });

    group('mapResponse', () {
      test('maps 401 to InvalidCredentials', () {
        final response = Response<dynamic>(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        );
        final result = ErrorMapper.mapResponse(response);
        expect(result, isA<InvalidCredentials>());
      });

      test('maps 403 with EMAIL_NOT_VERIFIED to EmailNotVerified', () {
        final response = Response(
          statusCode: 403,
          data: {'code': 'EMAIL_NOT_VERIFIED'},
          requestOptions: RequestOptions(path: '/test'),
        );
        final result = ErrorMapper.mapResponse(response);
        expect(result, isA<EmailNotVerified>());
      });

      test('maps 409 to UserAlreadyExists', () {
        final response = Response<dynamic>(
          statusCode: 409,
          requestOptions: RequestOptions(path: '/test'),
        );
        final result = ErrorMapper.mapResponse(response);
        expect(result, isA<UserAlreadyExists>());
      });

      test('maps 400 with INVALID_TOKEN to InvalidToken', () {
        final response = Response(
          statusCode: 400,
          data: {'code': 'INVALID_TOKEN'},
          requestOptions: RequestOptions(path: '/test'),
        );
        final result = ErrorMapper.mapResponse(response);
        expect(result, isA<InvalidToken>());
      });

      test('uses onCode callback for plugin-specific errors', () {
        final response = Response(
          statusCode: 404,
          data: {'code': 'SSO_PROVIDER_NOT_FOUND', 'message': 'No provider'},
          requestOptions: RequestOptions(path: '/test'),
        );

        final result = ErrorMapper.mapResponse(
          response,
          onCode: (code, message) => switch (code) {
            'SSO_PROVIDER_NOT_FOUND' => const SSOProviderNotFound(),
            _ => null,
          },
        );

        expect(result, isA<SSOProviderNotFound>());
      });

      test('falls back to standard mapping when onCode returns null', () {
        final response = Response(
          statusCode: 401,
          data: {'code': 'UNKNOWN_CODE'},
          requestOptions: RequestOptions(path: '/test'),
        );

        final result = ErrorMapper.mapResponse(
          response,
          onCode: (code, message) => null, // Don't handle
        );

        expect(result, isA<InvalidCredentials>());
      });

      test('extracts message from response', () {
        final response = Response(
          statusCode: 500,
          data: {'message': 'Internal server error'},
          requestOptions: RequestOptions(path: '/test'),
        );

        final result = ErrorMapper.mapResponse(response);

        expect(result, isA<UnknownError>());
        expect(result.message, 'Internal server error');
      });
    });
  });
}
