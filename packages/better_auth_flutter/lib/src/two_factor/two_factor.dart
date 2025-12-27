import 'package:better_auth_flutter/src/client/error_mapper.dart';
import 'package:better_auth_flutter/src/client/plugin_context.dart';
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
  TwoFactor(this._ctx);

  final PluginContext _ctx;

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
        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/two-factor/enable',
          data: {
            'password': password,
            if (issuer != null) 'issuer': issuer,
          },
        );

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        return TwoFactorSetup.fromJson(response.data as Map<String, dynamic>);
      },
      ErrorMapper.map,
    );
  }

  /// Get TOTP URI for displaying QR code.
  ///
  /// Useful for re-displaying the QR code after initial setup.
  TaskEither<AuthError, String> getTotpUri({required String password}) {
    return TaskEither.tryCatch(
      () async {
        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/two-factor/get-totp-uri',
          data: {'password': password},
        );

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        final data = response.data as Map<String, dynamic>;
        return data['totpURI'] as String;
      },
      ErrorMapper.map,
    );
  }

  /// Disable two-factor authentication.
  TaskEither<AuthError, Unit> disable({required String password}) {
    return TaskEither.tryCatch(
      () async {
        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/two-factor/disable',
          data: {'password': password},
        );

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        return unit;
      },
      ErrorMapper.map,
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
        _ctx.emitState(const AuthLoading());

        final response = await _ctx.dio.post<dynamic>(
          endpoint,
          data: {
            'code': code,
            if (trustDevice) 'trustDevice': true,
          },
        );

        if (response.statusCode != 200) {
          _ctx.emitState(const Unauthenticated());
          throw _mapResponse(response);
        }

        final responseData = response.data as Map<String, dynamic>;
        final user = User.fromJson(
          responseData['user'] as Map<String, dynamic>,
        );

        // BetterAuth may return either:
        // - 'session' object (legacy format)
        // - 'token' at top level (bearer plugin format)
        final Session session;
        final sessionData = responseData['session'] as Map<String, dynamic>?;
        if (sessionData != null) {
          session = Session.fromJson(sessionData);
        } else {
          // Extract token from top level or response header
          final token = responseData['token'] as String? ??
              response.headers.value('set-auth-token');
          if (token == null) {
            throw const UnknownError(
              message: 'No session or token in response',
              code: 'INVALID_RESPONSE',
            );
          }
          session = Session(
            id: token,
            userId: user.id,
            token: token,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          );
        }

        await _ctx.storage.saveUser(user).run();
        await _ctx.storage.saveSession(session).run();

        final state = Authenticated(user: user, session: session);
        _ctx.emitState(state);

        return state;
      },
      (error, stackTrace) {
        _ctx.emitState(const Unauthenticated());
        return ErrorMapper.map(error, stackTrace);
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
        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/two-factor/generate-backup-codes',
          data: {'password': password},
        );

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        final data = response.data as Map<String, dynamic>;
        return (data['backupCodes'] as List).cast<String>();
      },
      ErrorMapper.map,
    );
  }

  // === Error Handling ===

  /// Map response to two-factor-specific errors, falling back to standard mapping.
  AuthError _mapResponse(Response<dynamic> response) {
    return ErrorMapper.mapResponse(
      response,
      onCode: (code, message) => switch (code) {
        'INVALID_CODE' =>
          UnknownError(message: message ?? 'Invalid code', code: code),
        'TWO_FACTOR_ALREADY_ENABLED' =>
          UnknownError(message: message ?? 'Already enabled', code: code),
        'TWO_FACTOR_NOT_ENABLED' =>
          UnknownError(message: message ?? 'Not enabled', code: code),
        _ => null, // Fall back to standard mapping
      },
    );
  }
}
