import 'package:better_auth_flutter/src/models/user.dart';

/// Extension to check if a user is anonymous.
///
/// Anonymous users can later be upgraded to full accounts by linking
/// email/password or social credentials.
extension AnonymousUserExtension on User {
  /// Whether this is an anonymous (guest) user.
  ///
  /// Returns `true` if:
  /// - The email is empty, or
  /// - The email starts with `anonymous_` (BetterAuth placeholder)
  ///
  /// Example:
  /// ```dart
  /// if (currentUser.isAnonymous) {
  ///   showCreateAccountPrompt();
  /// }
  /// ```
  bool get isAnonymous => email.isEmpty || email.startsWith('anonymous_');
}
