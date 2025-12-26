import 'package:flutter/foundation.dart';

/// Credential returned from an OAuth provider's native SDK.
///
/// Contains the tokens needed to authenticate with the BetterAuth server.
@immutable
final class OAuthCredential {
  /// Creates an [OAuthCredential].
  ///
  /// - [idToken]: Required. The ID token from the OAuth provider.
  /// - [accessToken]: Optional. The access token if provided by the provider.
  /// - [nonce]: Optional. Required by Apple Sign In for security.
  const OAuthCredential({
    required this.idToken,
    this.accessToken,
    this.nonce,
  });

  /// The ID token from the OAuth provider.
  ///
  /// This is the primary credential used for server-side validation.
  final String idToken;

  /// Optional access token from the OAuth provider.
  ///
  /// Some providers (like Google) provide this for additional API access.
  final String? accessToken;

  /// Optional nonce for security.
  ///
  /// Required by Apple Sign In to prevent replay attacks.
  final String? nonce;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OAuthCredential &&
          runtimeType == other.runtimeType &&
          idToken == other.idToken &&
          accessToken == other.accessToken &&
          nonce == other.nonce;

  @override
  int get hashCode => Object.hash(idToken, accessToken, nonce);

  @override
  String toString() => 'OAuthCredential(idToken: [REDACTED], '
      'accessToken: ${accessToken != null ? "[REDACTED]" : "null"}, '
      'nonce: ${nonce != null ? "[REDACTED]" : "null"})';
}
