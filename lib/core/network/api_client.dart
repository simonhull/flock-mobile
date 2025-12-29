import 'package:dio/dio.dart';
import 'package:flock/core/error/failure.dart';
import 'package:flock/core/network/auth_interceptor.dart';
import 'package:fpdart/fpdart.dart';

/// HTTP client for API requests.
///
/// Wraps Dio with:
/// - Automatic auth token injection
/// - Consistent error handling
/// - TaskEither-based responses
abstract interface class ApiClient {
  /// GET request returning parsed JSON.
  TaskEither<Failure, Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  /// POST request with JSON body.
  TaskEither<Failure, Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  });

  /// POST multipart form data (for file uploads).
  TaskEither<Failure, Map<String, dynamic>> postMultipart(
    String path, {
    required FormData formData,
  });

  /// PATCH request with JSON body.
  TaskEither<Failure, Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  });

  /// DELETE request.
  TaskEither<Failure, Map<String, dynamic>> delete(String path);
}

/// Dio-based implementation of [ApiClient].
final class ApiClientImpl implements ApiClient {
  ApiClientImpl({
    required String baseUrl,
    required AuthInterceptor authInterceptor,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )..interceptors.add(authInterceptor);

  final Dio _dio;

  @override
  TaskEither<Failure, Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _request(() => _dio.get<Map<String, dynamic>>(
            path,
            queryParameters: queryParameters,
          ));

  @override
  TaskEither<Failure, Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) =>
      _request(() => _dio.post<Map<String, dynamic>>(path, data: data));

  @override
  TaskEither<Failure, Map<String, dynamic>> postMultipart(
    String path, {
    required FormData formData,
  }) =>
      _request(() => _dio.post<Map<String, dynamic>>(
            path,
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          ));

  @override
  TaskEither<Failure, Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) =>
      _request(() => _dio.patch<Map<String, dynamic>>(path, data: data));

  @override
  TaskEither<Failure, Map<String, dynamic>> delete(String path) =>
      _request(() => _dio.delete<Map<String, dynamic>>(path));

  /// Wraps a Dio request with error handling.
  TaskEither<Failure, Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) =>
      TaskEither.tryCatch(
        () async {
          final response = await request();
          return response.data ?? {};
        },
        _mapError,
      );

  /// Maps Dio exceptions to domain Failures.
  Failure _mapError(Object error, StackTrace stackTrace) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          const NetworkFailure('Connection timed out.'),
        DioExceptionType.connectionError =>
          const NetworkFailure('No internet connection.'),
        DioExceptionType.badResponse => _mapStatusCode(error.response),
        DioExceptionType.cancel => const NetworkFailure('Request cancelled.'),
        _ => const UnexpectedFailure(),
      };
    }
    return const UnexpectedFailure();
  }

  /// Maps HTTP status codes to appropriate Failures.
  Failure _mapStatusCode(Response<dynamic>? response) {
    if (response == null) return const UnexpectedFailure();

    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    final message = data is Map<String, dynamic>
        ? (data['error'] as String?) ?? 'Server error'
        : 'Server error';

    return switch (statusCode) {
      400 => ValidationFailure(message),
      401 => const AuthFailure(),
      403 => const AuthFailure('Access denied.'),
      404 => const NotFoundFailure(),
      >= 500 => ServerFailure(message, statusCode: statusCode),
      _ => ServerFailure(message, statusCode: statusCode),
    };
  }
}
