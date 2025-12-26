import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:dio/dio.dart';

/// Centralized error mapping for the auth system.
///
/// Plugins use this instead of duplicating error mapping code.
/// Provides standard mappings for HTTP status codes and Dio errors,
/// with extension points for plugin-specific error codes.
///
/// Usage in plugins:
/// ```dart
/// TaskEither.tryCatch(
///   () async { ... },
///   ErrorMapper.map,  // Use directly as error handler
/// );
///
/// // Or for response-specific mapping with custom codes:
/// if (response.statusCode != 200) {
///   throw ErrorMapper.mapResponse(
///     response,
///     onCode: (code, msg) => switch (code) {
///       'MY_PLUGIN_ERROR' => const MyPluginError(),
///       _ => null,  // Fall back to standard mapping
///     },
///   );
/// }
/// ```
abstract final class ErrorMapper {
  /// Map any error to an [AuthError].
  ///
  /// - Returns [AuthError] unchanged
  /// - Maps [DioException] to appropriate error types
  /// - Wraps unknown errors in [UnknownError]
  static AuthError map(Object error, StackTrace stackTrace) {
    if (error is AuthError) return error;

    if (error is DioException) {
      if (error.response != null) {
        return mapResponse(error.response!);
      }
      if (_isConnectionError(error)) {
        return const NetworkError();
      }
    }

    return UnknownError(message: error.toString());
  }

  /// Map HTTP response to [AuthError] based on status code and error code.
  ///
  /// [onCode] - Optional callback for plugin-specific error codes.
  /// Return the appropriate [AuthError] for known codes, or `null`
  /// to fall back to standard mapping.
  ///
  /// Standard mappings:
  /// - 401 → [InvalidCredentials]
  /// - 403 + EMAIL_NOT_VERIFIED → [EmailNotVerified]
  /// - 409 → [UserAlreadyExists]
  /// - 400 + INVALID_TOKEN → [InvalidToken]
  /// - Other → [UnknownError] with message from response
  static AuthError mapResponse(
    Response<dynamic> response, {
    AuthError? Function(String code, String? message)? onCode,
  }) {
    final data = response.data;
    final status = response.statusCode;

    String? code;
    String? message;

    if (data is Map<String, dynamic>) {
      code = data['code'] as String?;
      message = data['message'] as String?;
    }

    // Let plugin handle its specific codes first
    if (code != null && onCode != null) {
      final pluginError = onCode(code, message);
      if (pluginError != null) return pluginError;
    }

    // Fall back to standard mappings
    return switch (status) {
      401 => const InvalidCredentials(),
      403 when code == 'EMAIL_NOT_VERIFIED' => const EmailNotVerified(),
      409 => const UserAlreadyExists(),
      400 when code == 'INVALID_TOKEN' => const InvalidToken(),
      _ => UnknownError(message: message ?? 'Request failed', code: code),
    };
  }

  static bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout;
}
