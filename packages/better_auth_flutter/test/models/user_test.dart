import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User', () {
    final now = DateTime.utc(2024, 1, 1, 12);

    test('creates from constructor', () {
      final user = User(
        id: '123',
        email: 'test@example.com',
        emailVerified: true,
        createdAt: now,
        updatedAt: now,
        name: 'Test User',
      );

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.emailVerified, true);
    });

    test('creates from JSON', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'name': 'Test User',
        'image': 'https://example.com/avatar.png',
        'emailVerified': true,
        'createdAt': '2024-01-01T12:00:00.000Z',
        'updatedAt': '2024-01-01T12:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.image, 'https://example.com/avatar.png');
      expect(user.emailVerified, true);
    });

    test('serializes to JSON', () {
      final user = User(
        id: '123',
        email: 'test@example.com',
        emailVerified: true,
        createdAt: now,
        updatedAt: now,
        name: 'Test User',
      );

      final json = user.toJson();

      expect(json['id'], '123');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
      expect(json['emailVerified'], true);
    });

    test('copyWith creates new instance with updated fields', () {
      final user = User(
        id: '123',
        email: 'test@example.com',
        emailVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      final updated = user.copyWith(emailVerified: true, name: 'New Name');

      expect(updated.id, '123');
      expect(updated.email, 'test@example.com');
      expect(updated.name, 'New Name');
      expect(updated.emailVerified, true);
    });

    test('equality based on id', () {
      final user1 = User(
        id: '123',
        email: 'test@example.com',
        emailVerified: true,
        createdAt: now,
        updatedAt: now,
      );

      final user2 = User(
        id: '123',
        email: 'different@example.com',
        emailVerified: false,
        createdAt: now,
        updatedAt: now,
      );

      final user3 = User(
        id: '456',
        email: 'test@example.com',
        emailVerified: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });
}
