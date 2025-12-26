import 'package:better_auth_flutter/src/client/better_auth_client.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:fpdart/fpdart.dart';

/// Extension providing proactive session validation.
///
/// Use this to refresh sessions before they expire, avoiding mid-operation
/// authentication failures.
extension SessionValidationExtension on BetterAuthClient {
  /// Validates the session and refreshes if expiring soon.
  ///
  /// Returns the current session if valid, or a refreshed session if the
  /// current one is expiring within [threshold]. If not authenticated,
  /// returns [NotAuthenticated] error.
  ///
  /// Use this before critical operations that must not fail due to
  /// expired sessions:
  ///
  /// ```dart
  /// final result = await client.validateSession().run();
  /// switch (result) {
  ///   case Right(:final value):
  ///     // Session valid, proceed with operation
  ///     await performCriticalOperation(value.token);
  ///   case Left(:final value):
  ///     // Handle error (likely need to re-authenticate)
  ///     showLoginScreen();
  /// }
  /// ```
  TaskEither<AuthError, Session> validateSession({
    Duration threshold = const Duration(minutes: 5),
  }) {
    return TaskEither(() async {
      final state = currentState;

      switch (state) {
        case Authenticated(:final session):
          if (session.isExpiringSoon(threshold)) {
            // Proactively refresh
            return getSession().run();
          }
          return right(session);

        case AuthLoading():
          // Wait briefly and retry - client is initializing
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return validateSession(threshold: threshold).run();

        case AuthInitial():
        case Unauthenticated():
          return left(const NotAuthenticated());
      }
    });
  }

  /// Checks if the current session is still valid without refreshing.
  ///
  /// Returns `true` if there is a valid, non-expired session.
  /// Returns `false` otherwise (including if session is expiring soon).
  bool get hasValidSession {
    final state = currentState;
    switch (state) {
      case Authenticated(:final session):
        return session.isValid && !session.isExpiringSoon();
      case AuthLoading():
      case AuthInitial():
      case Unauthenticated():
        return false;
    }
  }

  /// Time until the current session expires, or null if not authenticated.
  Duration? get timeUntilExpiry {
    final state = currentState;
    switch (state) {
      case Authenticated(:final session):
        final now = DateTime.now();
        if (session.expiresAt.isAfter(now)) {
          return session.expiresAt.difference(now);
        }
        return Duration.zero;
      case AuthLoading():
      case AuthInitial():
      case Unauthenticated():
        return null;
    }
  }
}
