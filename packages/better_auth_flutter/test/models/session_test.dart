import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Session', () {
    test('creates from constructor', () {
      final expiresAt = DateTime.now().add(const Duration(hours: 1));

      final session = Session(
        id: 'session-123',
        userId: 'user-456',
        token: 'token-abc',
        expiresAt: expiresAt,
      );

      expect(session.id, 'session-123');
      expect(session.userId, 'user-456');
      expect(session.token, 'token-abc');
      expect(session.expiresAt, expiresAt);
    });

    test('creates from JSON', () {
      final json = {
        'id': 'session-123',
        'userId': 'user-456',
        'token': 'token-abc',
        'expiresAt': '2025-01-01T12:00:00.000Z',
      };

      final session = Session.fromJson(json);

      expect(session.id, 'session-123');
      expect(session.userId, 'user-456');
      expect(session.token, 'token-abc');
      expect(session.expiresAt, DateTime.utc(2025, 1, 1, 12));
    });

    test('serializes to JSON', () {
      final expiresAt = DateTime.utc(2025, 1, 1, 12);

      final session = Session(
        id: 'session-123',
        userId: 'user-456',
        token: 'token-abc',
        expiresAt: expiresAt,
      );

      final json = session.toJson();

      expect(json['id'], 'session-123');
      expect(json['userId'], 'user-456');
      expect(json['token'], 'token-abc');
      expect(json['expiresAt'], '2025-01-01T12:00:00.000Z');
    });

    test('isExpired returns true for past date', () {
      final session = Session(
        id: 'session-123',
        userId: 'user-456',
        token: 'token-abc',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(session.isExpired, true);
      expect(session.isValid, false);
    });

    test('isExpired returns false for future date', () {
      final session = Session(
        id: 'session-123',
        userId: 'user-456',
        token: 'token-abc',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(session.isExpired, false);
      expect(session.isValid, true);
    });

    test('equality based on id', () {
      final session1 = Session(
        id: 'session-123',
        userId: 'user-456',
        token: 'token-abc',
        expiresAt: DateTime.now(),
      );

      final session2 = Session(
        id: 'session-123',
        userId: 'user-789',
        token: 'token-xyz',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      final session3 = Session(
        id: 'session-456',
        userId: 'user-456',
        token: 'token-abc',
        expiresAt: DateTime.now(),
      );

      expect(session1, equals(session2));
      expect(session1, isNot(equals(session3)));
    });
  });
}
