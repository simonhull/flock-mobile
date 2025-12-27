import 'package:better_auth_flutter/src/client/error_mapper.dart';
import 'package:better_auth_flutter/src/client/plugin_context.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/magic_link_sent.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Magic link (passwordless) authentication capability.
///
/// Enables sign-in via email links - no password required.
///
/// Usage:
/// ```dart
/// final magicLink = MagicLink(client);
///
/// // Send magic link email
/// await magicLink.send(email: 'user@example.com').run();
///
/// // After user clicks link and app extracts token:
/// await magicLink.verify(token: extractedToken).run();
/// ```
final class MagicLink {
  MagicLink(this._ctx);

  final PluginContext _ctx;

  /// Send a magic link to the email address.
  ///
  /// If [createUser] is true (default), creates a new account if one
  /// doesn't exist. Set to false to require existing accounts only.
  ///
  /// [callbackURL] is the URL the magic link will redirect to. This should
  /// be a deep link your app can handle (e.g., `myapp://auth/magic`).
  TaskEither<AuthError, MagicLinkSent> send({
    required String email,
    bool createUser = true,
    String? callbackURL,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _ctx.dio.post<dynamic>(
          '/api/auth/magic-link/send',
          data: {
            'email': email,
            'createUser': createUser,
            if (callbackURL != null) 'callbackURL': callbackURL,
          },
        );

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        return MagicLinkSent.fromJson(response.data as Map<String, dynamic>);
      },
      ErrorMapper.map,
    );
  }

  /// Verify a magic link token and sign in.
  ///
  /// Call this after the user clicks the magic link and you've extracted
  /// the token from the deep link URL.
  ///
  /// Example deep link handling:
  /// ```dart
  /// // Incoming URL: myapp://auth/magic?token=xxx
  /// final token = uri.queryParameters['token'];
  /// if (token != null) {
  ///   await magicLink.verify(token: token).run();
  /// }
  /// ```
  TaskEither<AuthError, Authenticated> verify({required String token}) {
    return TaskEither.tryCatch(
      () async {
        _ctx.emitState(const AuthLoading());

        final response = await _ctx.dio.get<dynamic>(
          '/api/auth/magic-link/verify',
          queryParameters: {'token': token},
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

  // === Error Handling ===

  /// Map response to magic-link-specific errors, falling back to standard mapping.
  AuthError _mapResponse(Response<dynamic> response) {
    return ErrorMapper.mapResponse(
      response,
      onCode: (code, message) => switch (code) {
        'MAGIC_LINK_EXPIRED' => const MagicLinkExpired(),
        'MAGIC_LINK_INVALID' || 'INVALID_TOKEN' => const MagicLinkInvalid(),
        'MAGIC_LINK_USED' => const MagicLinkAlreadyUsed(),
        'USER_NOT_FOUND' => UnknownError(
            message: message ?? 'No account found with this email',
            code: code,
          ),
        _ => null, // Fall back to standard mapping
      },
    );
  }
}
