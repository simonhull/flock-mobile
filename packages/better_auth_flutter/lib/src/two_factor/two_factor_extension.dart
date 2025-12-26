import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/two_factor/two_factor.dart';

/// Extension that adds two-factor authentication to [BetterAuthClientImpl].
///
/// Usage:
/// ```dart
/// // Enable 2FA
/// final setup = await client.twoFactor.enable(password: 'password').run();
///
/// // Display QR code from setup.totpUri
/// // User scans with authenticator app
///
/// // Later, during sign-in with 2FA enabled:
/// final signInResult = await client.signIn(...).run();
/// if (signInResult case Left(value: TwoFactorRequired())) {
///   // Prompt for code
///   await client.twoFactor.verifyTotp(code: userCode).run();
/// }
/// ```
extension TwoFactorExtension on BetterAuthClientImpl {
  static final _instances = Expando<TwoFactor>('TwoFactor');

  /// Two-factor authentication capability.
  ///
  /// Provides methods to enable, disable, and verify 2FA.
  TwoFactor get twoFactor => _instances[this] ??= TwoFactor(this);
}
