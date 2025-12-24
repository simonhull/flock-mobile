import 'package:better_auth_flutter/src/models/models.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract interface for auth storage operations.
///
/// All operations return [TaskEither] for consistent error handling
/// and lazy async composition.
abstract interface class AuthStorage {
  /// Store session data.
  TaskEither<AuthError, Unit> saveSession(Session session);

  /// Retrieve stored session.
  ///
  /// Returns [None] if no session exists.
  TaskEither<AuthError, Option<Session>> getSession();

  /// Store user data.
  TaskEither<AuthError, Unit> saveUser(User user);

  /// Retrieve stored user.
  ///
  /// Returns [None] if no user exists.
  TaskEither<AuthError, Option<User>> getUser();

  /// Clear all auth data.
  TaskEither<AuthError, Unit> clear();
}
