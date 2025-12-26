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

/// User is not authenticated.
///
/// This occurs when an operation requires authentication but no
/// valid session exists.
final class NotAuthenticated extends AuthError {
  const NotAuthenticated()
      : super(message: 'Please sign in to continue');
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

// === Two-Factor Errors ===

/// Sign-in requires two-factor authentication.
///
/// This error indicates the user has 2FA enabled and must complete
/// verification before sign-in can succeed. The partial session is
/// maintained via cookies - call `twoFactor.verifyTotp()` or
/// `twoFactor.verifyBackupCode()` to complete authentication.
final class TwoFactorRequired extends AuthError {
  const TwoFactorRequired()
      : super(message: 'Two-factor authentication required');
}

// === OAuth Errors ===

/// User cancelled the OAuth flow.
///
/// This is not an error condition - it's expected behavior when
/// users dismiss the sign-in dialog.
final class OAuthCancelled extends AuthError {
  const OAuthCancelled() : super(message: 'Sign in cancelled');
}

/// OAuth provider is not configured correctly.
///
/// This typically indicates a developer error, such as:
/// - Missing client ID
/// - Invalid bundle identifier
/// - Misconfigured redirect URI
final class OAuthConfigurationError extends AuthError {
  const OAuthConfigurationError({required this.details})
      : super(message: 'OAuth configuration error: $details');

  /// Details about the configuration problem.
  final String details;
}

/// OAuth provider SDK returned an error.
///
/// This wraps errors from the native Google/Apple/etc. SDKs.
final class OAuthProviderError extends AuthError {
  const OAuthProviderError({
    required this.provider,
    required this.details,
  }) : super(message: '$provider error: $details');

  /// Which provider failed (e.g., "Google", "Apple").
  final String provider;

  /// Details about the failure.
  final String details;
}

/// Server rejected the OAuth token.
///
/// This occurs when the BetterAuth server cannot validate
/// the token received from the OAuth provider.
final class OAuthTokenRejected extends AuthError {
  const OAuthTokenRejected({this.reason})
      : super(message: reason ?? 'Token rejected by server');

  /// Optional reason for rejection.
  final String? reason;
}
