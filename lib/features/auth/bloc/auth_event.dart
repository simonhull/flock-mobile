import 'package:better_auth_flutter/better_auth_flutter.dart' as ba;

/// Events for the global [AuthBloc].
sealed class AuthEvent {
  const AuthEvent();
}

/// Request to check/restore auth state on app startup.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Request to sign out the current user.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Internal event when BetterAuth client state changes.
///
/// This is emitted by the AuthBloc when it receives updates from
/// [BetterAuthClient.authStateChanges].
final class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.authState);

  final ba.AuthState authState;
}
