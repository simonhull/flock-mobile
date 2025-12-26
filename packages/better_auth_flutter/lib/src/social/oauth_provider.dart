import 'package:better_auth_flutter/src/social/oauth_credential.dart';

/// Interface for OAuth providers.
///
/// Implement this interface to add support for new OAuth providers.
/// Each provider handles its own native SDK interaction and returns
/// a standardized [OAuthCredential] for server exchange.
///
/// Example implementation:
/// ```dart
/// final class MyOAuthProvider implements OAuthProvider {
///   @override
///   String get providerId => 'my-provider';
///
///   @override
///   Future<OAuthCredential> authenticate() async {
///     // Call native SDK
///     final result = await MyNativeSDK.signIn();
///     return OAuthCredential(idToken: result.idToken);
///   }
/// }
/// ```
abstract interface class OAuthProvider {
  /// Unique identifier for this provider.
  ///
  /// Must match the provider ID expected by the BetterAuth server.
  /// Common values: "google", "apple", "github", "discord", etc.
  String get providerId;

  /// Trigger the native OAuth flow and return credentials.
  ///
  /// This method should:
  /// 1. Launch the provider's native sign-in UI
  /// 2. Handle user interaction
  /// 3. Return [OAuthCredential] on success
  /// 4. Throw an `AuthError` subtype on failure
  ///
  /// Throws:
  /// - `OAuthCancelled` if user dismisses the sign-in dialog
  /// - `OAuthProviderError` if the SDK returns an error
  /// - `OAuthConfigurationError` if the provider is misconfigured
  Future<OAuthCredential> authenticate();
}
