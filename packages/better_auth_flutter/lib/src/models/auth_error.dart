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

// === Magic Link Errors ===

/// Magic link has expired.
///
/// The user clicked a link that is no longer valid.
/// They should request a new magic link.
final class MagicLinkExpired extends AuthError {
  const MagicLinkExpired()
      : super(message: 'Magic link has expired', code: 'MAGIC_LINK_EXPIRED');
}

/// Magic link token is invalid.
///
/// The token may be malformed or tampered with.
final class MagicLinkInvalid extends AuthError {
  const MagicLinkInvalid()
      : super(message: 'Invalid magic link', code: 'MAGIC_LINK_INVALID');
}

/// Magic link has already been used.
///
/// Magic links are single-use for security. The user should
/// request a new one if they need to sign in again.
final class MagicLinkAlreadyUsed extends AuthError {
  const MagicLinkAlreadyUsed()
      : super(
          message: 'Magic link has already been used',
          code: 'MAGIC_LINK_USED',
        );
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

// === Anonymous Auth Errors ===

/// Current user is not an anonymous user.
///
/// This error occurs when attempting to link credentials to a user
/// that is not anonymous. Only anonymous users can be upgraded
/// to full accounts via linking.
final class NotAnonymous extends AuthError {
  const NotAnonymous()
      : super(
          message: 'Current user is not anonymous',
          code: 'NOT_ANONYMOUS',
        );
}

/// Anonymous account is already linked to credentials.
///
/// This error occurs when attempting to link an anonymous account
/// that has already been upgraded to a full account.
final class AccountAlreadyLinked extends AuthError {
  const AccountAlreadyLinked()
      : super(
          message: 'Account is already linked to credentials',
          code: 'ACCOUNT_ALREADY_LINKED',
        );
}

// === Passkey Errors ===

/// Passkeys are not supported on this device.
///
/// The device lacks WebAuthn/FIDO2 hardware support or
/// the required platform APIs are unavailable.
final class PasskeyNotSupported extends AuthError {
  const PasskeyNotSupported()
      : super(
          message: 'Passkeys not supported on this device',
          code: 'PASSKEY_NOT_SUPPORTED',
        );
}

/// User cancelled the passkey operation.
///
/// This is not an error condition - it's expected behavior when
/// users dismiss the biometric prompt.
final class PasskeyCancelled extends AuthError {
  const PasskeyCancelled()
      : super(
          message: 'Passkey operation cancelled',
          code: 'PASSKEY_CANCELLED',
        );
}

/// No passkey found for this account.
///
/// The user hasn't registered a passkey, or the registered
/// passkey is no longer available on this device.
final class PasskeyNotFound extends AuthError {
  const PasskeyNotFound()
      : super(
          message: 'No passkey found for this account',
          code: 'PASSKEY_NOT_FOUND',
        );
}

/// Passkey verification failed.
///
/// The server could not verify the passkey signature.
/// This may indicate a tampered credential or server misconfiguration.
final class PasskeyVerificationFailed extends AuthError {
  const PasskeyVerificationFailed()
      : super(
          message: 'Passkey verification failed',
          code: 'PASSKEY_VERIFICATION_FAILED',
        );
}

// === SSO Errors ===

/// No SSO provider is configured for the user's email domain.
///
/// This occurs when attempting SSO sign-in with an email domain
/// that doesn't have a configured identity provider.
final class SSOProviderNotFound extends AuthError {
  const SSOProviderNotFound()
      : super(
          message: 'No SSO provider configured for this domain',
          code: 'SSO_PROVIDER_NOT_FOUND',
        );
}

/// SSO provider exists but is currently disabled.
///
/// The organization's SSO provider has been deactivated.
/// Contact the organization administrator.
final class SSOProviderDisabled extends AuthError {
  const SSOProviderDisabled()
      : super(
          message: 'SSO provider is disabled',
          code: 'SSO_PROVIDER_DISABLED',
        );
}

/// Error occurred during SSO callback processing.
///
/// The identity provider returned an error or the callback
/// could not be processed correctly.
final class SSOCallbackError extends AuthError {
  const SSOCallbackError({required super.message})
      : super(code: 'SSO_CALLBACK_ERROR');
}

/// SSO state parameter mismatch.
///
/// The state returned from the identity provider doesn't match
/// the state sent in the authorization request. This could
/// indicate a CSRF attack or session timeout.
final class SSOStateMismatch extends AuthError {
  const SSOStateMismatch()
      : super(
          message: 'SSO state mismatch - possible CSRF attack',
          code: 'SSO_STATE_MISMATCH',
        );
}

/// User cancelled the SSO sign-in flow.
///
/// This is not an error condition - it's expected behavior when
/// users dismiss the browser or cancel authentication.
final class SSOCancelled extends AuthError {
  const SSOCancelled()
      : super(
          message: 'SSO sign-in cancelled',
          code: 'SSO_CANCELLED',
        );
}
