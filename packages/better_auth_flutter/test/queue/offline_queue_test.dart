import 'package:better_auth_flutter/src/queue/offline_queue.dart';
import 'package:better_auth_flutter/src/queue/queued_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QueuedOperation', () {
    test('QueuedSignOut has correct type', () {
      final op = QueuedSignOut(createdAt: DateTime.now());
      expect(op, isA<QueuedOperation>());
    });

    test('QueuedVerificationEmail stores email', () {
      final op = QueuedVerificationEmail(
        createdAt: DateTime.now(),
      );
      expect(op, isA<QueuedOperation>());
    });

    test('QueuedForgotPassword stores email', () {
      final op = QueuedForgotPassword(
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );
      expect(op.email, 'test@example.com');
    });

    test('isExpired returns true for old operations', () {
      final op = QueuedSignOut(
        createdAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(op.isExpired, isTrue);
    });

    test('isExpired returns false for recent operations', () {
      final op = QueuedSignOut(
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(op.isExpired, isFalse);
    });
  });

  group('OfflineQueue', () {
    late OfflineQueue queue;

    setUp(() {
      queue = OfflineQueueImpl();
    });

    test('starts empty', () async {
      final result = await queue.pending().run();

      result.fold(
        (error) => fail('Expected Right'),
        (ops) => expect(ops, isEmpty),
      );
    });

    test('enqueue adds operation', () async {
      final op = QueuedSignOut(createdAt: DateTime.now());

      await queue.enqueue(op).run();
      final result = await queue.pending().run();

      result.fold(
        (error) => fail('Expected Right'),
        (ops) {
          expect(ops, hasLength(1));
          expect(ops.first, isA<QueuedSignOut>());
        },
      );
    });

    test('clear removes all operations', () async {
      await queue.enqueue(QueuedSignOut(createdAt: DateTime.now())).run();
      await queue
          .enqueue(QueuedForgotPassword(
            email: 'test@example.com',
            createdAt: DateTime.now(),
          ))
          .run();

      await queue.clear().run();
      final result = await queue.pending().run();

      result.fold(
        (error) => fail('Expected Right'),
        (ops) => expect(ops, isEmpty),
      );
    });

    test('pending excludes expired operations', () async {
      // Add expired operation
      await queue
          .enqueue(QueuedSignOut(
            createdAt: DateTime.now().subtract(const Duration(hours: 25)),
          ))
          .run();

      // Add valid operation
      await queue
          .enqueue(QueuedForgotPassword(
            email: 'test@example.com',
            createdAt: DateTime.now(),
          ))
          .run();

      final result = await queue.pending().run();

      result.fold(
        (error) => fail('Expected Right'),
        (ops) {
          expect(ops, hasLength(1));
          expect(ops.first, isA<QueuedForgotPassword>());
        },
      );
    });
  });
}
