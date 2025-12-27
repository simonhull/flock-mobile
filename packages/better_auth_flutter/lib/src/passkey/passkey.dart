import 'package:better_auth_flutter/src/client/error_mapper.dart';
import 'package:better_auth_flutter/src/client/plugin_context.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:better_auth_flutter/src/passkey/passkey_authenticator.dart';
import 'package:better_auth_flutter/src/passkey/passkey_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Passkey (WebAuthn) authentication capability.
///
/// Enables passwordless authentication using biometrics (Face ID, Touch ID,
/// fingerprint) or device PIN via the WebAuthn/FIDO2 standard.
///
/// Usage:
/// ```dart
/// final authenticator = MyPasskeyAuthenticator();
///
/// // Register a new passkey (user must be signed in)
/// await client.passkey.register(authenticator: authenticator).run();
///
/// // Authenticate with passkey
/// await client.passkey.authenticate(authenticator: authenticator).run();
///
/// // List registered passkeys
/// await client.passkey.list().run();
///
/// // Remove a passkey
/// await client.passkey.remove(passkeyId: 'pk-123').run();
/// ```
final class Passkey {
  Passkey(this._ctx);

  final PluginContext _ctx;

  /// Register a new passkey for the current user.
  ///
  /// User must be authenticated. Creates a new credential on device
  /// and stores the public key on the server.
  ///
  /// [authenticator] - Platform-specific WebAuthn implementation.
  /// [name] - Optional friendly name for the passkey (e.g., "iPhone 15 Pro").
  ///
  /// Returns [PasskeyInfo] on success.
  /// Throws [PasskeyNotSupported] if device doesn't support passkeys.
  /// Throws [PasskeyCancelled] if user cancels the biometric prompt.
  /// Throws [PasskeyVerificationFailed] if server rejects the credential.
  TaskEither<AuthError, PasskeyInfo> register({
    required PasskeyAuthenticator authenticator,
    String? name,
  }) {
    return TaskEither.tryCatch(
      () async {
        // 1. Check device support
        if (!await authenticator.isAvailable()) {
          throw const PasskeyNotSupported();
        }

        // 2. Get registration options from server
        final optionsResponse = await _ctx.dio.post<dynamic>(
          '/api/auth/passkey/generate-registration-options',
        );

        if (optionsResponse.statusCode != 200) {
          throw _mapResponse(optionsResponse);
        }

        final options = RegistrationOptions.fromJson(
          optionsResponse.data as Map<String, dynamic>,
        );

        // 3. Create credential with platform authenticator
        final credential = await authenticator.createCredential(options);

        // 4. Send to server for verification
        final verifyResponse = await _ctx.dio.post<dynamic>(
          '/api/auth/passkey/verify-registration',
          data: {
            ...credential.toJson(),
            if (name != null) 'name': name,
          },
        );

        if (verifyResponse.statusCode != 200) {
          throw _mapResponse(verifyResponse);
        }

        return PasskeyInfo.fromJson(
          verifyResponse.data as Map<String, dynamic>,
        );
      },
      _mapError,
    );
  }

  /// Authenticate with a passkey.
  ///
  /// Can be used for initial sign-in or re-authentication.
  ///
  /// [authenticator] - Platform-specific WebAuthn implementation.
  /// [email] - Optional email to filter credentials. If provided, only
  ///   credentials for that user are allowed.
  ///
  /// Returns [Authenticated] on success.
  /// Throws [PasskeyNotSupported] if device doesn't support passkeys.
  /// Throws [PasskeyCancelled] if user cancels the biometric prompt.
  /// Throws [PasskeyNotFound] if no passkey exists for the account.
  TaskEither<AuthError, Authenticated> authenticate({
    required PasskeyAuthenticator authenticator,
    String? email,
  }) {
    return TaskEither.tryCatch(
      () async {
        _ctx.emitState(const AuthLoading());

        // 1. Check device support
        if (!await authenticator.isAvailable()) {
          throw const PasskeyNotSupported();
        }

        // 2. Get authentication options from server
        final optionsResponse = await _ctx.dio.post<dynamic>(
          '/api/auth/passkey/generate-authentication-options',
          data: <String, dynamic>{
            if (email != null) 'email': email,
          },
        );

        if (optionsResponse.statusCode != 200) {
          throw _mapResponse(optionsResponse);
        }

        final options = AuthenticationOptions.fromJson(
          optionsResponse.data as Map<String, dynamic>,
        );

        // 3. Get assertion from platform authenticator
        final assertion = await authenticator.getAssertion(options);

        // 4. Send to server for verification
        final verifyResponse = await _ctx.dio.post<dynamic>(
          '/api/auth/passkey/verify-authentication',
          data: assertion.toJson(),
        );

        if (verifyResponse.statusCode != 200) {
          throw _mapResponse(verifyResponse);
        }

        final data = verifyResponse.data as Map<String, dynamic>;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);

        // BetterAuth may return either:
        // - 'session' object (legacy format)
        // - 'token' at top level (bearer plugin format)
        final Session session;
        final sessionData = data['session'] as Map<String, dynamic>?;
        if (sessionData != null) {
          session = Session.fromJson(sessionData);
        } else {
          // Extract token from top level or response header
          final token = data['token'] as String? ??
              verifyResponse.headers.value('set-auth-token');
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
        return _mapError(error, stackTrace);
      },
    );
  }

  /// List all passkeys for current user.
  ///
  /// Returns a list of [PasskeyInfo] containing registered passkeys.
  TaskEither<AuthError, List<PasskeyInfo>> list() {
    return TaskEither.tryCatch(
      () async {
        final response = await _ctx.dio.get<dynamic>('/api/auth/passkey/list');

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        final data = response.data as Map<String, dynamic>;
        final passkeys = (data['passkeys'] as List<dynamic>)
            .map((p) => PasskeyInfo.fromJson(p as Map<String, dynamic>))
            .toList();

        return passkeys;
      },
      _mapError,
    );
  }

  /// Remove a passkey.
  ///
  /// [passkeyId] - The ID of the passkey to remove.
  ///
  /// Throws [PasskeyNotFound] if the passkey doesn't exist.
  TaskEither<AuthError, Unit> remove({required String passkeyId}) {
    return TaskEither.tryCatch(
      () async {
        final response = await _ctx.dio.delete<dynamic>(
          '/api/auth/passkey/$passkeyId',
        );

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        return unit;
      },
      _mapError,
    );
  }

  // === Error Handling ===

  /// Map response to passkey-specific errors, falling back to standard mapping.
  AuthError _mapResponse(Response<dynamic> response) {
    return ErrorMapper.mapResponse(
      response,
      onCode: (code, message) => switch (code) {
        'PASSKEY_NOT_FOUND' => const PasskeyNotFound(),
        'VERIFICATION_FAILED' || 'INVALID_CHALLENGE' =>
          const PasskeyVerificationFailed(),
        _ => null, // Fall back to standard mapping
      },
    );
  }

  /// Map any error to AuthError, with passkey-specific handling.
  AuthError _mapError(Object error, StackTrace stackTrace) {
    // Handle passkey-specific: platform authenticator errors
    if (error is! AuthError && error is! DioException) {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('cancel')) {
        return const PasskeyCancelled();
      }
      if (errorString.contains('not supported') ||
          errorString.contains('not available')) {
        return const PasskeyNotSupported();
      }
    }

    // Delegate to shared mapper
    return ErrorMapper.map(error, stackTrace);
  }
}
