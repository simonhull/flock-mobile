import 'dart:math';

import 'package:dio/dio.dart';

/// Key for tracking retry attempts in request options.
const _retryCountKey = 'retry_count';

/// Interceptor that retries failed requests with exponential backoff.
final class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration baseDelay;

  final _random = Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = _getRetryCount(err.requestOptions);
    final maxForThisError = _maxRetriesFor(err);

    if (_shouldRetry(err) && retryCount < maxForThisError) {
      // Apply exponential backoff with jitter
      final delay = _calculateDelay(retryCount);
      await Future<void>.delayed(delay);

      try {
        final options = err.requestOptions;
        options.extra[_retryCountKey] = retryCount + 1;

        final response = await _dio.fetch<dynamic>(options);
        handler.resolve(response);
        return;
      } on DioException catch (e) {
        // Recursively handle the new error (may retry again)
        await onError(e, handler);
        return;
      }
    }

    handler.next(err);
  }

  Duration _calculateDelay(int retryCount) {
    // Exponential backoff: baseDelay * 2^retryCount
    final exponentialMs = baseDelay.inMilliseconds * pow(2, retryCount);

    // Add jitter (±20%)
    final jitter = 0.8 + (_random.nextDouble() * 0.4);
    final delayMs = (exponentialMs * jitter).round();

    return Duration(milliseconds: delayMs);
  }

  int _getRetryCount(RequestOptions options) {
    return options.extra[_retryCountKey] as int? ?? 0;
  }

  int _maxRetriesFor(DioException err) {
    // 401 only gets 1 retry (cookie may have refreshed)
    if (err.response?.statusCode == 401) return 1;
    return maxRetries;
  }

  bool _shouldRetry(DioException err) {
    final statusCode = err.response?.statusCode;

    return switch (err.type) {
      DioExceptionType.connectionTimeout => true,
      DioExceptionType.connectionError => true,
      DioExceptionType.badResponse when statusCode != null =>
        statusCode >= 500 || statusCode == 401,
      _ => false,
    };
  }
}
