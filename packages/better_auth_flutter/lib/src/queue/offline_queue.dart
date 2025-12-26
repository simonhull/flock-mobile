import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/queue/queued_operation.dart';
import 'package:fpdart/fpdart.dart';

/// Interface for offline operation queue.
abstract interface class OfflineQueue {
  /// Add an operation to the queue.
  TaskEither<AuthError, Unit> enqueue(QueuedOperation operation);

  /// Get all pending (non-expired) operations.
  TaskEither<AuthError, List<QueuedOperation>> pending();

  /// Clear all queued operations.
  TaskEither<AuthError, Unit> clear();
}

/// In-memory implementation of [OfflineQueue].
///
/// For production, use a persistent implementation backed by secure storage.
final class OfflineQueueImpl implements OfflineQueue {
  final List<QueuedOperation> _operations = [];

  @override
  TaskEither<AuthError, Unit> enqueue(QueuedOperation operation) {
    return TaskEither.tryCatch(
      () async {
        _operations.add(operation);
        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to enqueue: $error'),
    );
  }

  @override
  TaskEither<AuthError, List<QueuedOperation>> pending() {
    return TaskEither.tryCatch(
      () async {
        // Filter out expired operations
        return _operations.where((op) => !op.isExpired).toList();
      },
      (error, _) => UnknownError(message: 'Failed to get pending: $error'),
    );
  }

  @override
  TaskEither<AuthError, Unit> clear() {
    return TaskEither.tryCatch(
      () async {
        _operations.clear();
        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to clear: $error'),
    );
  }
}
