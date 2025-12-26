import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
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
  MagicLink(this._client);

  final BetterAuthClientImpl _client;

  Dio get _dio => _client.internalDio;

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
        final response = await _dio.post<dynamic>(
          '/api/auth/magic-link/send',
          data: {
            'email': email,
            'createUser': createUser,
            if (callbackURL != null) 'callbackURL': callbackURL,
          },
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        return MagicLinkSent.fromJson(response.data as Map<String, dynamic>);
      },
      _mapError,
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
        _client.internalStateController.add(const AuthLoading());

        final response = await _dio.get<dynamic>(
          '/api/auth/magic-link/verify',
          queryParameters: {'token': token},
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
      'MAGIC_LINK_EXPIRED' => const MagicLinkExpired(),
      'MAGIC_LINK_INVALID' || 'INVALID_TOKEN' => const MagicLinkInvalid(),
      'MAGIC_LINK_USED' => const MagicLinkAlreadyUsed(),
      'USER_NOT_FOUND' => UnknownError(
          message: message ?? 'No account found with this email',
          code: code,
        ),
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
