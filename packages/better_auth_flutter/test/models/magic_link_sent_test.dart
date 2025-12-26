import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MagicLinkSent', () {
    test('creates from constructor', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));
      final sent = MagicLinkSent(
        email: 'user@example.com',
        expiresAt: expiresAt,
      );

      expect(sent.email, 'user@example.com');
      expect(sent.expiresAt, expiresAt);
    });

    test('creates from JSON', () {
      final json = {
        'email': 'user@example.com',
        'expiresAt': '2024-01-15T12:30:00.000Z',
      };

      final sent = MagicLinkSent.fromJson(json);

      expect(sent.email, 'user@example.com');
      expect(sent.expiresAt, DateTime.utc(2024, 1, 15, 12, 30));
    });

    test('equality based on all fields', () {
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));
      final sent1 = MagicLinkSent(email: 'a@example.com', expiresAt: expiresAt);
      final sent2 = MagicLinkSent(email: 'a@example.com', expiresAt: expiresAt);
      final sent3 = MagicLinkSent(email: 'b@example.com', expiresAt: expiresAt);

      expect(sent1, equals(sent2));
      expect(sent1, isNot(equals(sent3)));
    });

    test('toString includes email', () {
      final sent = MagicLinkSent(
        email: 'user@example.com',
        expiresAt: DateTime.now(),
      );

      expect(sent.toString(), contains('user@example.com'));
    });
  });
}
