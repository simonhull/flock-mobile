/// Interface for handling browser-based SSO authentication flows.
///
/// SSO requires opening an external browser or WebView to the identity
/// provider's login page, then capturing the callback URL when the user
/// completes authentication.
///
/// Users implement this interface using their preferred method:
///
/// **Using flutter_web_auth_2 (recommended):**
/// ```dart
/// import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
///
/// final class FlutterWebAuthHandler implements SSOBrowserHandler {
///   @override
///   Future<Uri> openAndWaitForCallback({
///     required Uri authorizationUrl,
///     required Uri callbackUrl,
///   }) async {
///     final result = await FlutterWebAuth2.authenticate(
///       url: authorizationUrl.toString(),
///       callbackUrlScheme: callbackUrl.scheme,
///     );
///     return Uri.parse(result);
///   }
/// }
/// ```
///
/// **Using url_launcher + deep links:**
/// ```dart
/// final class DeepLinkHandler implements SSOBrowserHandler {
///   @override
///   Future<Uri> openAndWaitForCallback({
///     required Uri authorizationUrl,
///     required Uri callbackUrl,
///   }) async {
///     await launchUrl(authorizationUrl);
///     return _waitForDeepLink(callbackUrl.scheme);
///   }
/// }
/// ```
abstract interface class SSOBrowserHandler {
  /// Open the authorization URL and wait for callback.
  ///
  /// Implementation should:
  /// 1. Open [authorizationUrl] in browser or WebView
  /// 2. Wait for redirect to [callbackUrl]
  /// 3. Return the full callback URL including query parameters
  ///
  /// The returned URI will contain:
  /// - `code`: Authorization code for OIDC/OAuth2
  /// - `state`: State parameter for CSRF validation
  /// - Or `error` / `error_description` if authentication failed
  ///
  /// Throws if user cancels the flow or an error occurs.
  Future<Uri> openAndWaitForCallback({
    required Uri authorizationUrl,
    required Uri callbackUrl,
  });
}
