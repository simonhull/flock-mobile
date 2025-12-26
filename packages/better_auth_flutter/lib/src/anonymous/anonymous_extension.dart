import 'package:better_auth_flutter/src/anonymous/anonymous.dart';
import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';

/// Extension that adds anonymous authentication to [BetterAuthClientImpl].
///
/// Usage:
/// ```dart
/// // Sign in anonymously
/// await client.anonymous.signIn().run();
///
/// // Later, upgrade to full account
/// await client.anonymous.linkEmail(
///   email: 'user@example.com',
///   password: 'password',
/// ).run();
/// ```
extension AnonymousExtension on BetterAuthClientImpl {
  static final _instances = Expando<Anonymous>('Anonymous');

  /// Anonymous (guest) authentication capability.
  Anonymous get anonymous => _instances[this] ??= Anonymous(this);
}
