import 'package:flutter/foundation.dart';

/// Expiration duration for queued operations.
const _expirationDuration = Duration(hours: 24);

/// Base class for operations that can be queued for offline execution.
@immutable
sealed class QueuedOperation {
  const QueuedOperation({required this.createdAt});

  /// When this operation was created.
  final DateTime createdAt;

  /// Whether this operation has expired and should be discarded.
  bool get isExpired =>
      DateTime.now().difference(createdAt) > _expirationDuration;
}

/// Queued sign-out operation.
final class QueuedSignOut extends QueuedOperation {
  const QueuedSignOut({required super.createdAt});
}

/// Queued verification email request.
final class QueuedVerificationEmail extends QueuedOperation {
  const QueuedVerificationEmail({required super.createdAt});
}

/// Queued forgot password request.
final class QueuedForgotPassword extends QueuedOperation {
  const QueuedForgotPassword({
    required this.email,
    required super.createdAt,
  });

  /// Email address to send reset link to.
  final String email;
}
