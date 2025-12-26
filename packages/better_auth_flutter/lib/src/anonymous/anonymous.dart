import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:better_auth_flutter/src/social/oauth_provider.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Anonymous (guest) authentication capability.
///
/// Enables users to interact with your app without creating an account.
/// Later, they can upgrade to a full account by linking email/password
/// or social credentials — preserving all their data.
///
/// Usage:
/// ```dart
/// final anonymous = Anonymous(client);
///
/// // Sign in anonymously
/// await anonymous.signIn().run();
///
/// // Later, upgrade to full account
/// await anonymous.linkEmail(
///   email: 'user@example.com',
///   password: 'password',
/// ).run();
/// ```
final class Anonymous {
  Anonymous(this._client);

  final BetterAuthClientImpl _client;

  Dio get _dio => _client.internalDio;

  /// Sign in anonymously.
  ///
  /// Creates a temporary user account that can later be upgraded
  /// to a full account using [linkEmail] or [linkSocial].
  ///
  /// Example:
  /// ```dart
  /// final result = await anonymous.signIn().run();
  /// switch (result) {
  ///   case Right(:final value):
  ///     print('Signed in as guest: ${value.user.id}');
  ///   case Left(:final value):
  ///     print('Failed: ${value.message}');
  /// }
  /// ```
  TaskEither<AuthError, Authenticated> signIn() {
    return TaskEither.tryCatch(
      () async {
        _client.internalStateController.add(const AuthLoading());

        final response = await _dio.post<dynamic>(
          '/api/auth/anonymous/sign-in',
          data: <String, dynamic>{},
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

  /// Link anonymous account to email/password.
  ///
  /// Upgrades the anonymous user to a full account with email credentials.
  /// The user's data and ID are preserved.
  ///
  /// Throws [NotAnonymous] if the current user is not anonymous.
  /// Throws [UserAlreadyExists] if the email is already in use.
  /// Throws [AccountAlreadyLinked] if already linked to credentials.
  ///
  /// Example:
  /// ```dart
  /// final result = await anonymous.linkEmail(
  ///   email: 'user@example.com',
  ///   password: 'password',
  ///   name: 'John Doe',
  /// ).run();
  /// ```
  TaskEither<AuthError, Authenticated> linkEmail({
    required String email,
    required String password,
    String? name,
  }) {
    return TaskEither.tryCatch(
      () async {
        _client.internalStateController.add(const AuthLoading());

        final response = await _dio.post<dynamic>(
          '/api/auth/anonymous/link',
          data: {
            'email': email,
            'password': password,
            if (name != null) 'name': name,
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

  /// Link anonymous account to social provider.
  ///
  /// Upgrades the anonymous user using OAuth credentials.
  ///
  /// Throws [NotAnonymous] if the current user is not anonymous.
  /// Throws [AccountAlreadyLinked] if already linked to credentials.
  /// Throws [OAuthCancelled] if the user cancels the OAuth flow.
  ///
  /// Example:
  /// ```dart
  /// final result = await anonymous.linkSocial(
  ///   provider: GoogleOAuthProvider(),
  /// ).run();
  /// ```
  TaskEither<AuthError, Authenticated> linkSocial({
    required OAuthProvider provider,
  }) {
    return TaskEither.tryCatch(
      () async {
        _client.internalStateController.add(const AuthLoading());

        // Get OAuth credential from provider
        final credential = await provider.authenticate();

        final response = await _dio.post<dynamic>(
          '/api/auth/anonymous/link',
          data: {
            'providerId': provider.providerId,
            'idToken': credential.idToken,
            'accessToken': credential.accessToken,
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

  // === Error Handling ===

  AuthError _mapStatusToError(Response<dynamic> response) {
    final data = response.data;

    String? code;
    String? message;

    if (data is Map<String, dynamic>) {
      code = data['code'] as String?;
      message = data['message'] as String?;
    }

    return switch (code) {
      'NOT_ANONYMOUS' => const NotAnonymous(),
      'EMAIL_ALREADY_EXISTS' || 'USER_ALREADY_EXISTS' =>
        const UserAlreadyExists(),
      'ACCOUNT_ALREADY_LINKED' => const AccountAlreadyLinked(),
      _ => UnknownError(message: message ?? 'Request failed', code: code),
    };
  }

  AuthError _mapError(Object error, StackTrace stackTrace) {
    if (error is AuthError) return error;

    if (error is DioException) {
      if (error.response != null) {
        return _mapStatusToError(error.response!);
      }
      return const NetworkError();
    }

    return UnknownError(message: error.toString());
  }
}
