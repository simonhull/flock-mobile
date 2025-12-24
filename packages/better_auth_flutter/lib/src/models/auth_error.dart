/// Error types for authentication operations.
///
/// Sealed class hierarchy enables exhaustive switch expressions.
sealed class AuthError implements Exception {
  const AuthError({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthError($code): $message';
}

/// Network connectivity error.
final class NetworkError extends AuthError {
  const NetworkError({super.message = 'No internet connection', super.code});
}

/// Invalid email or password.
final class InvalidCredentials extends AuthError {
  const InvalidCredentials()
      : super(message: 'Invalid email or password');
}

/// Email address not verified.
final class EmailNotVerified extends AuthError {
  const EmailNotVerified()
      : super(message: 'Please verify your email');
}

/// Account with this email already exists.
final class UserAlreadyExists extends AuthError {
  const UserAlreadyExists()
      : super(message: 'An account with this email already exists');
}

/// Session token has expired.
final class TokenExpired extends AuthError {
  const TokenExpired()
      : super(message: 'Session expired, please sign in again');
}

/// Invalid or expired reset/verification token.
final class InvalidToken extends AuthError {
  const InvalidToken()
      : super(message: 'Invalid or expired token');
}

/// Unknown or unmapped error.
final class UnknownError extends AuthError {
  const UnknownError({required super.message, super.code});
}
