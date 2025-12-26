import 'package:flutter/foundation.dart';

/// Data returned when enabling two-factor authentication.
///
/// Contains everything needed to complete 2FA setup:
/// - [totpUri] for generating a QR code
/// - [secret] for manual entry into authenticator apps
/// - [backupCodes] for account recovery
@immutable
final class TwoFactorSetup {
  const TwoFactorSetup({
    required this.totpUri,
    required this.secret,
    required this.backupCodes,
  });

  factory TwoFactorSetup.fromJson(Map<String, dynamic> json) {
    return TwoFactorSetup(
      totpUri: json['totpURI'] as String,
      secret: json['secret'] as String,
      backupCodes: (json['backupCodes'] as List).cast<String>(),
    );
  }

  /// TOTP URI for QR code generation.
  ///
  /// Format: `otpauth://totp/{issuer}:{account}?secret={secret}&issuer={issuer}`
  final String totpUri;

  /// Base32-encoded secret for manual entry.
  final String secret;

  /// One-time backup codes for account recovery.
  ///
  /// Store these securely - each can only be used once.
  final List<String> backupCodes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TwoFactorSetup &&
          runtimeType == other.runtimeType &&
          totpUri == other.totpUri &&
          secret == other.secret &&
          listEquals(backupCodes, other.backupCodes);

  @override
  int get hashCode => Object.hash(totpUri, secret, Object.hashAll(backupCodes));

  @override
  String toString() => 'TwoFactorSetup(${backupCodes.length} backup codes)';
}
