import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/magic_link/magic_link.dart';

/// Extension that adds magic link authentication to [BetterAuthClientImpl].
///
/// Usage:
/// ```dart
/// // Send magic link
/// await client.magicLink.send(email: 'user@example.com').run();
///
/// // After user clicks link and app extracts token:
/// await client.magicLink.verify(token: extractedToken).run();
/// ```
extension MagicLinkExtension on BetterAuthClientImpl {
  static final _instances = Expando<MagicLink>('MagicLink');

  /// Magic link (passwordless) authentication capability.
  MagicLink get magicLink => _instances[this] ??= MagicLink(this);
}
