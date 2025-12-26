import 'package:better_auth_flutter/src/client/error_mapper.dart';
import 'package:better_auth_flutter/src/client/plugin_context.dart';
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
  Anonymous(this._ctx);

  final PluginContext _ctx;

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
        _ctx.emitState(const AuthLoading());

        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/anonymous/sign-in',
          data: <String, dynamic>{},
        );

        if (response.statusCode != 200) {
          _ctx.emitState(const Unauthenticated());
          throw _mapResponse(response);
        }

        final responseData = response.data as Map<String, dynamic>;
        final user = User.fromJson(
          responseData['user'] as Map<String, dynamic>,
        );
        final session = Session.fromJson(
          responseData['session'] as Map<String, dynamic>,
        );

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
        _ctx.emitState(const AuthLoading());

        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/anonymous/link',
          data: {
            'email': email,
            'password': password,
            if (name != null) 'name': name,
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
        final session = Session.fromJson(
          responseData['session'] as Map<String, dynamic>,
        );

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
        _ctx.emitState(const AuthLoading());

        // Get OAuth credential from provider
        final credential = await provider.authenticate();

        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/anonymous/link',
          data: {
            'providerId': provider.providerId,
            'idToken': credential.idToken,
            'accessToken': credential.accessToken,
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
        final session = Session.fromJson(
          responseData['session'] as Map<String, dynamic>,
        );

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

  // === Error Handling ===

  /// Map response to anonymous-specific errors, falling back to standard mapping.
  AuthError _mapResponse(Response<dynamic> response) {
    return ErrorMapper.mapResponse(
      response,
      onCode: (code, message) => switch (code) {
        'NOT_ANONYMOUS' => const NotAnonymous(),
        'EMAIL_ALREADY_EXISTS' || 'USER_ALREADY_EXISTS' =>
          const UserAlreadyExists(),
        'ACCOUNT_ALREADY_LINKED' => const AccountAlreadyLinked(),
        _ => null, // Fall back to standard mapping
      },
    );
  }
}
