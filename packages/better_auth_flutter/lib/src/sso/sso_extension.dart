import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/sso/sso.dart';

/// Extension to add SSO capability to BetterAuthClient.
extension SSOExtension on BetterAuthClientImpl {
  static final _instances = Expando<SSO>('SSO');

  /// Enterprise SSO (OIDC/SAML/OAuth2) authentication.
  ///
  /// Usage:
  /// ```dart
  /// // Check if SSO is available for email domain
  /// final provider = await client.sso.checkDomain(
  ///   email: 'user@company.com',
  /// ).run();
  ///
  /// if (provider != null && provider.isEnabled) {
  ///   // SSO available, use it
  ///   await client.sso.signIn(
  ///     email: 'user@company.com',
  ///     browserHandler: FlutterWebAuthHandler(),
  ///   ).run();
  /// } else {
  ///   // Fall back to email/password
  ///   showPasswordLogin();
  /// }
  /// ```
  SSO get sso => _instances[this] ??= SSO(pluginContext);
}
