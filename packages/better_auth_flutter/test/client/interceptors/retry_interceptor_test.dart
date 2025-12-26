import 'package:better_auth_flutter/src/client/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeDioException extends Fake implements DioException {}

class FakeResponse extends Fake implements Response<dynamic> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
    registerFallbackValue(FakeResponse());
  });

  group('RetryInterceptor', () {
    late RetryInterceptor interceptor;
    late MockDio mockDio;
    late MockErrorInterceptorHandler mockHandler;

    setUp(() {
      mockDio = MockDio();
      mockHandler = MockErrorInterceptorHandler();
      interceptor = RetryInterceptor(dio: mockDio);
    });

    test('does not retry on 400 Bad Request', () async {
      final requestOptions = RequestOptions(path: '/test');
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 400,
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );

      await interceptor.onError(error, mockHandler);

      // Should pass error through without retrying
      verify(() => mockHandler.next(error)).called(1);
      verifyNever(() => mockDio.fetch<dynamic>(any()));
    });

    test('retries on connection timeout and succeeds', () async {
      final requestOptions = RequestOptions(path: '/test');
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );
      final successResponse = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {'success': true},
      );

      when(() => mockDio.fetch<dynamic>(any()))
          .thenAnswer((_) async => successResponse);

      await interceptor.onError(error, mockHandler);

      // Should retry and resolve with success
      verify(() => mockDio.fetch<dynamic>(any())).called(1);
      verify(() => mockHandler.resolve(successResponse)).called(1);
      verifyNever(() => mockHandler.next(any()));
    });

    test('gives up after 3 retries', () async {
      final requestOptions = RequestOptions(path: '/test');
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );

      // Always fail
      when(() => mockDio.fetch<dynamic>(any())).thenThrow(error);

      await interceptor.onError(error, mockHandler);

      // Should attempt 3 retries then give up
      verify(() => mockDio.fetch<dynamic>(any())).called(3);
      verify(() => mockHandler.next(any())).called(1);
      verifyNever(() => mockHandler.resolve(any()));
    });

    test('retries on 5xx server error', () async {
      final requestOptions = RequestOptions(path: '/test');
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 503,
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
      final successResponse = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 200,
        data: {'success': true},
      );

      when(() => mockDio.fetch<dynamic>(any()))
          .thenAnswer((_) async => successResponse);

      await interceptor.onError(error, mockHandler);

      verify(() => mockDio.fetch<dynamic>(any())).called(1);
      verify(() => mockHandler.resolve(successResponse)).called(1);
    });

    test('retries 401 once then fails', () async {
      final requestOptions = RequestOptions(path: '/test');
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 401,
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );

      // Always fail with 401
      when(() => mockDio.fetch<dynamic>(any())).thenThrow(error);

      await interceptor.onError(error, mockHandler);

      // Should retry exactly once, then give up
      verify(() => mockDio.fetch<dynamic>(any())).called(1);
      verify(() => mockHandler.next(any())).called(1);
    });

    test('applies exponential backoff delay between retries', () async {
      final requestOptions = RequestOptions(path: '/test');
      final error = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionTimeout,
      );
      final successResponse = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 200,
      );

      var callCount = 0;
      when(() => mockDio.fetch<dynamic>(any())).thenAnswer((_) async {
        callCount++;
        if (callCount < 3) throw error;
        return successResponse;
      });

      final stopwatch = Stopwatch()..start();
      await interceptor.onError(error, mockHandler);
      stopwatch.stop();

      // With base delay 500ms: attempt 2 waits ~500ms, attempt 3 waits ~1000ms
      // Total should be at least 1200ms (accounting for jitter reducing delays)
      expect(stopwatch.elapsedMilliseconds, greaterThan(1200));
      verify(() => mockDio.fetch<dynamic>(any())).called(3);
    });
  });
}
