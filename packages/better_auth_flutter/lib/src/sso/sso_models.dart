import 'package:flutter/foundation.dart' show immutable;

/// Information about a configured SSO provider.
///
/// SSO providers are configured on the server and allow users to
/// authenticate using their organization's identity provider
/// (Okta, Azure AD, Google Workspace, etc.).
@immutable
final class SSOProvider {
  const SSOProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.isEnabled,
    required this.createdAt,
    this.domain,
    this.organizationId,
  });

  factory SSOProvider.fromJson(Map<String, dynamic> json) {
    return SSOProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isEnabled: json['isEnabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      domain: json['domain'] as String?,
      organizationId: json['organizationId'] as String?,
    );
  }

  /// Unique identifier for this provider.
  final String id;

  /// Human-readable name (e.g., "Acme Corp Okta").
  final String name;

  /// Provider type: 'oidc', 'saml', or 'oauth2'.
  final String type;

  /// Whether this provider is currently active.
  final bool isEnabled;

  /// When this provider was configured.
  final DateTime createdAt;

  /// Email domain this provider handles (e.g., "acme.com").
  /// Used for automatic domain-based routing.
  final String? domain;

  /// Optional organization ID this provider belongs to.
  final String? organizationId;
}

/// Response from server containing IdP authorization URL.
///
/// When initiating SSO, the server returns this response with
/// the URL to open in a browser and the expected callback URL.
@immutable
final class SSOAuthorizationResponse {
  const SSOAuthorizationResponse({
    required this.authorizationUrl,
    required this.callbackUrl,
    required this.providerId,
    required this.state,
  });

  factory SSOAuthorizationResponse.fromJson(Map<String, dynamic> json) {
    return SSOAuthorizationResponse(
      authorizationUrl: Uri.parse(json['authorizationUrl'] as String),
      callbackUrl: Uri.parse(json['callbackUrl'] as String),
      providerId: json['providerId'] as String,
      state: json['state'] as String,
    );
  }

  /// URL to open in browser for IdP authentication.
  final Uri authorizationUrl;

  /// Expected callback URL (app should intercept redirects here).
  final Uri callbackUrl;

  /// Provider being used for this flow.
  final String providerId;

  /// State parameter for CSRF protection.
  /// Must be validated when callback is received.
  final String state;
}
