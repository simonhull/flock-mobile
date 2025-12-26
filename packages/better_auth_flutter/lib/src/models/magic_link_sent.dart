import 'package:flutter/foundation.dart';

/// Response after successfully sending a magic link email.
@immutable
final class MagicLinkSent {
  const MagicLinkSent({
    required this.email,
    required this.expiresAt,
  });

  factory MagicLinkSent.fromJson(Map<String, dynamic> json) {
    return MagicLinkSent(
      email: json['email'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Email address the magic link was sent to.
  final String email;

  /// When the magic link expires.
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MagicLinkSent &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(email, expiresAt);

  @override
  String toString() => 'MagicLinkSent(email: $email)';
}
