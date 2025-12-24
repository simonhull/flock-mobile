import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:flutter/foundation.dart';

/// Authentication state.
///
/// Sealed class hierarchy for exhaustive switch expressions.
@immutable
sealed class AuthState {
  const AuthState();
}

/// Initial state before initialization.
@immutable
final class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  String toString() => 'AuthInitial()';
}

/// Loading state during auth operations.
@immutable
final class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  String toString() => 'AuthLoading()';
}

/// Authenticated state with user and session.
@immutable
final class Authenticated extends AuthState {
  const Authenticated({
    required this.user,
    required this.session,
  });

  final User user;
  final Session session;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          session == other.session;

  @override
  int get hashCode => Object.hash(user, session);

  @override
  String toString() => 'Authenticated(user: ${user.email})';
}

/// Unauthenticated state.
@immutable
final class Unauthenticated extends AuthState {
  const Unauthenticated();

  @override
  String toString() => 'Unauthenticated()';
}
