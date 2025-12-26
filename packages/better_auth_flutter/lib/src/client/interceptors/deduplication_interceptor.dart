import 'dart:async';

import 'package:dio/dio.dart';

/// Interceptor that prevents duplicate concurrent requests.
///
/// When the same mutating request (POST, PUT, DELETE, PATCH) is made multiple
/// times concurrently (e.g., double-tap on a button), only the first request
/// is actually sent. Subsequent identical requests wait for the first to
/// complete and receive the same response.
///
/// GET requests are not deduplicated as they are idempotent and may
/// intentionally be made multiple times.
///
/// Request identity is determined by method + path + data hash.
final class DeduplicationInterceptor extends Interceptor {
  /// Map of in-flight request keys to their completion Completers.
  final _inFlight = <String, Completer<Response<dynamic>>>{};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only deduplicate mutating requests
    if (options.method == 'GET') {
      return handler.next(options);
    }

    final key = _requestKey(options);

    // If this exact request is already in-flight, wait for it
    if (_inFlight.containsKey(key)) {
      try {
        final response = await _inFlight[key]!.future;
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.reject(e);
      }
    }

    // Mark this request as in-flight
    _inFlight[key] = Completer<Response<dynamic>>();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = _requestKey(response.requestOptions);

    // Complete the Completer for any waiters
    if (_inFlight.containsKey(key)) {
      _inFlight[key]!.complete(response);
      _inFlight.remove(key);
    }

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final key = _requestKey(err.requestOptions);

    // Complete the Completer with error for any waiters
    if (_inFlight.containsKey(key)) {
      _inFlight[key]!.completeError(err);
      _inFlight.remove(key);
    }

    handler.next(err);
  }

  /// Generate a unique key for a request based on method, path, and data.
  String _requestKey(RequestOptions options) {
    final dataHash = options.data?.hashCode ?? 0;
    return '${options.method}:${options.path}:$dataHash';
  }
}
