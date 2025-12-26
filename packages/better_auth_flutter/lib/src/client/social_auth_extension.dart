import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:better_auth_flutter/src/social/oauth_provider.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Extension that adds social authentication to [BetterAuthClientImpl].
///
/// Usage:
/// ```dart
/// final google = GoogleOAuthProvider(clientId: 'xxx');
/// final result = await client.signInWithProvider(google).run();
/// ```
extension SocialAuthExtension on BetterAuthClientImpl {
  /// Sign in using an OAuth provider.
  ///
  /// Flow:
  /// 1. Calls [provider.authenticate()] to get credentials from native SDK
  /// 2. Sends credentials to BetterAuth server at `/api/auth/sign-in/social`
  /// 3. Server validates token and returns session
  /// 4. Updates local auth state and persists session
  ///
  /// Returns [Authenticated] on success, or an [AuthError] on failure.
  ///
  /// Common errors:
  /// - [OAuthCancelled]: User dismissed the sign-in dialog (not an error)
  /// - [OAuthProviderError]: Native SDK failed
  /// - [InvalidCredentials]: Server rejected the token
  TaskEither<AuthError, Authenticated> signInWithProvider(
    OAuthProvider provider,
  ) {
    return TaskEither.tryCatch(
      () async {
        // Emit loading state
        internalStateController.add(const AuthLoading());

        // Step 1: Get credentials from native SDK
        final credential = await provider.authenticate();

        // Step 2: Build the idToken payload per BetterAuth spec
        final idTokenPayload = <String, dynamic>{
          'token': credential.idToken,
          if (credential.accessToken != null)
            'accessToken': credential.accessToken,
          if (credential.nonce != null) 'nonce': credential.nonce,
        };

        // Step 3: Send to server
        final response = await internalDio.post<dynamic>(
          '/api/auth/sign-in/social',
          data: {
            'provider': provider.providerId,
            'idToken': idTokenPayload,
          },
        );

        if (response.statusCode != 200) {
          internalStateController.add(const Unauthenticated());
          throw _mapStatusToError(response);
        }

        // Step 4: Parse response and update state
        final responseData = response.data as Map<String, dynamic>;
        final user = User.fromJson(
          responseData['user'] as Map<String, dynamic>,
        );
        final session = Session.fromJson(
          responseData['session'] as Map<String, dynamic>,
        );

        await internalStorage.saveUser(user).run();
        await internalStorage.saveSession(session).run();

        final state = Authenticated(user: user, session: session);
        internalStateController.add(state);

        return state;
      },
      (error, stackTrace) {
        internalStateController.add(const Unauthenticated());

        // Pass through auth errors directly (includes OAuth errors)
        if (error is AuthError) return error;

        if (error is DioException) {
          if (error.response != null) {
            return _mapStatusToError(error.response!);
          }
          return UnknownError(message: error.message ?? 'Network error');
        }

        return UnknownError(message: error.toString());
      },
    );
  }

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
      403 when code == 'EMAIL_NOT_VERIFIED' => const EmailNotVerified(),
      409 => const UserAlreadyExists(),
      400 when code == 'INVALID_TOKEN' => const InvalidToken(),
      _ => UnknownError(message: message ?? 'Request failed', code: code),
    };
  }
}
