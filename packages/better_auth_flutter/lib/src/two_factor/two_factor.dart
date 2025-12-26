import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/two_factor_setup.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Two-factor authentication capability.
///
/// Provides methods to enable, disable, and verify 2FA.
///
/// Usage:
/// ```dart
/// final twoFactor = TwoFactor(client);
///
/// // Enable 2FA
/// final setup = await twoFactor.enable(password: 'password').run();
///
/// // Verify during sign-in
/// final auth = await twoFactor.verifyTotp(code: '123456').run();
/// ```
final class TwoFactor {
  TwoFactor(this._client);

  final BetterAuthClientImpl _client;

  Dio get _dio => _client.internalDio;

  // === Setup ===

  /// Enable two-factor authentication.
  ///
  /// Returns [TwoFactorSetup] containing:
  /// - TOTP URI for QR code generation
  /// - Secret for manual entry
  /// - Backup codes for account recovery
  ///
  /// The user must verify a TOTP code after enabling for 2FA to be active.
  TaskEither<AuthError, TwoFactorSetup> enable({
    required String password,
    String? issuer,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post<dynamic>(
          '/api/auth/two-factor/enable',
          data: {
            'password': password,
            if (issuer != null) 'issuer': issuer,
          },
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        return TwoFactorSetup.fromJson(response.data as Map<String, dynamic>);
      },
      _mapError,
    );
  }

  /// Get TOTP URI for displaying QR code.
  ///
  /// Useful for re-displaying the QR code after initial setup.
  TaskEither<AuthError, String> getTotpUri({required String password}) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post<dynamic>(
          '/api/auth/two-factor/get-totp-uri',
          data: {'password': password},
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        final data = response.data as Map<String, dynamic>;
        return data['totpURI'] as String;
      },
      _mapError,
    );
  }

  /// Disable two-factor authentication.
  TaskEither<AuthError, Unit> disable({required String password}) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post<dynamic>(
          '/api/auth/two-factor/disable',
          data: {'password': password},
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        return unit;
      },
      _mapError,
    );
  }

  // === Verification ===

  /// Verify TOTP code during sign-in.
  ///
  /// Completes authentication when sign-in returns [TwoFactorRequired].
  /// Optionally marks this device as trusted to skip 2FA for 30 days.
  TaskEither<AuthError, Authenticated> verifyTotp({
    required String code,
    bool trustDevice = false,
  }) {
    return _verifyCode(
      endpoint: '/api/auth/two-factor/verify-totp',
      code: code,
      trustDevice: trustDevice,
    );
  }

  /// Verify backup code during sign-in.
  ///
  /// Use when the user doesn't have access to their authenticator app.
  /// Each backup code can only be used once.
  TaskEither<AuthError, Authenticated> verifyBackupCode({
    required String code,
    bool trustDevice = false,
  }) {
    return _verifyCode(
      endpoint: '/api/auth/two-factor/verify-backup-code',
      code: code,
      trustDevice: trustDevice,
    );
  }

  TaskEither<AuthError, Authenticated> _verifyCode({
    required String endpoint,
    required String code,
    required bool trustDevice,
  }) {
    return TaskEither.tryCatch(
      () async {
        _client.internalStateController.add(const AuthLoading());

        final response = await _dio.post<dynamic>(
          endpoint,
          data: {
            'code': code,
            if (trustDevice) 'trustDevice': true,
          },
        );

        if (response.statusCode != 200) {
          _client.internalStateController.add(const Unauthenticated());
          throw _mapStatusToError(response);
        }

        final responseData = response.data as Map<String, dynamic>;
        final user = User.fromJson(
          responseData['user'] as Map<String, dynamic>,
        );
        final session = Session.fromJson(
          responseData['session'] as Map<String, dynamic>,
        );

        await _client.internalStorage.saveUser(user).run();
        await _client.internalStorage.saveSession(session).run();

        final state = Authenticated(user: user, session: session);
        _client.internalStateController.add(state);

        return state;
      },
      (error, stackTrace) {
        _client.internalStateController.add(const Unauthenticated());
        return _mapError(error, stackTrace);
      },
    );
  }

  // === Backup Codes ===

  /// Generate new backup codes.
  ///
  /// Invalidates all existing backup codes and generates new ones.
  TaskEither<AuthError, List<String>> generateBackupCodes({
    required String password,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post<dynamic>(
          '/api/auth/two-factor/generate-backup-codes',
          data: {'password': password},
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        final data = response.data as Map<String, dynamic>;
        return (data['backupCodes'] as List).cast<String>();
      },
      _mapError,
    );
  }

  // === Error Handling ===

  AuthError _mapStatusToError(Response<dynamic> response) {
    final data = response.data;
    final statusCode = response.statusCode;

    String? code;
    String? message;

    if (data is Map<String, dynamic>) {
      code = data['code'] as String?;
      message = data['message'] as String?;
    }

    return switch (statusCode) {
      401 => const InvalidCredentials(),
      400 when code == 'INVALID_CODE' =>
        UnknownError(message: message ?? 'Invalid code', code: code),
      400 when code == 'TWO_FACTOR_ALREADY_ENABLED' =>
        UnknownError(message: message ?? 'Already enabled', code: code),
      400 when code == 'TWO_FACTOR_NOT_ENABLED' =>
        UnknownError(message: message ?? 'Not enabled', code: code),
      _ => UnknownError(message: message ?? 'Request failed', code: code),
    };
  }

  AuthError _mapError(Object error, StackTrace stackTrace) {
    if (error is AuthError) return error;

    if (error is DioException) {
      if (error.response != null) {
        return _mapStatusToError(error.response!);
      }
      return UnknownError(message: error.message ?? 'Network error');
    }

    return UnknownError(message: error.toString());
  }
}
