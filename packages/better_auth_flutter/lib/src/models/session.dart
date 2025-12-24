import 'package:flutter/foundation.dart';

/// Authentication session model.
///
/// Immutable representation of a BetterAuth session.
@immutable
final class Session {
  const Session({
    required this.id,
    required this.userId,
    required this.token,
    required this.expiresAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['userId'] as String,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String id;
  final String userId;
  final String token;
  final DateTime expiresAt;

  /// Whether this session has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this session is still valid.
  bool get isValid => !isExpired;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'token': token,
        'expiresAt': expiresAt.toIso8601String(),
      };

  Session copyWith({
    String? id,
    String? userId,
    String? token,
    DateTime? expiresAt,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Session(id: $id, userId: $userId)';
}
