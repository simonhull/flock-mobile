import 'package:better_auth_flutter/src/models/models.dart';
import 'package:fpdart/fpdart.dart';

/// Abstract interface for BetterAuth client.
///
/// All auth operations return [TaskEither] for consistent error handling
/// and lazy async composition.
abstract interface class BetterAuthClient {
  /// Stream of auth state changes.
  ///
  /// Emits new state on sign in, sign out, and initialization.
  Stream<AuthState> get authStateChanges;

  /// Current auth state (synchronous).
  AuthState get currentState;

  /// Current user if authenticated, null otherwise.
  User? get currentUser;

  // === Lifecycle ===

  /// Initialize client from stored session.
  ///
  /// Should be called once on app startup.
  /// Attempts to restore previous session from secure storage.
  TaskEither<AuthError, Unit> initialize();

  /// Dispose client and release resources.
  ///
  /// Should be called when the client is no longer needed.
  Future<void> dispose();

  // === Email/Password Authentication ===

  /// Sign up with email and password.
  ///
  /// Creates a new user account. The user may need to verify their email
  /// depending on server configuration.
  TaskEither<AuthError, Authenticated> signUp({
    required String email,
    required String password,
    String? name,
  });

  /// Sign in with email and password.
  ///
  /// Returns [InvalidCredentials] on wrong email/password.
  /// Returns [EmailNotVerified] if email verification is required.
  TaskEither<AuthError, Authenticated> signIn({
    required String email,
    required String password,
  });

  /// Sign out current user.
  ///
  /// Clears local session and notifies server.
  TaskEither<AuthError, Unit> signOut();

  // === Email Verification ===

  /// Send verification email.
  ///
  /// - [email]: Optional email address. If omitted, uses current user's email.
  /// - [callbackUrl]: Where to redirect after verification.
  TaskEither<AuthError, Unit> sendVerificationEmail({
    String? email,
    String? callbackUrl,
  });

  /// Verify email with token from verification link.
  TaskEither<AuthError, Unit> verifyEmail({required String token});

  // === Password Reset ===

  /// Request password reset email.
  ///
  /// Always succeeds (doesn't reveal if email exists).
  TaskEither<AuthError, Unit> forgotPassword({required String email});

  /// Reset password with token from reset email.
  TaskEither<AuthError, Unit> resetPassword({
    required String token,
    required String newPassword,
  });

  // === Session ===

  /// Get current session from server.
  ///
  /// Useful for checking session validity.
  TaskEither<AuthError, Session> getSession();
}
