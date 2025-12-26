import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/passkey/passkey.dart';

/// Extension that adds passkey capability to [BetterAuthClientImpl].
///
/// Usage:
/// ```dart
/// final authenticator = MyPasskeyAuthenticator();
///
/// // Register (after sign-in with another method)
/// await client.passkey.register(authenticator: authenticator).run();
///
/// // Authenticate
/// await client.passkey.authenticate(authenticator: authenticator).run();
///
/// // List registered passkeys
/// await client.passkey.list().run();
///
/// // Remove a passkey
/// await client.passkey.remove(passkeyId: 'pk-123').run();
/// ```
extension PasskeyExtension on BetterAuthClientImpl {
  static final _instances = Expando<Passkey>('Passkey');

  /// Passkey (WebAuthn) authentication capability.
  Passkey get passkey => _instances[this] ??= Passkey(this);
}
