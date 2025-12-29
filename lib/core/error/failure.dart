import 'package:equatable/equatable.dart';

/// Base failure type for domain-level errors.
///
/// Use sealed classes to enable exhaustive switch expressions.
/// Each failure carries a human-readable [message] for display.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Network-related failures (no connection, timeout, server error).
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Please try again.']);
}

/// Server returned an error response.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// Authentication failed (expired token, unauthorized).
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication required.']);
}

/// Validation failed (invalid input).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Resource not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

/// Unexpected error.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
