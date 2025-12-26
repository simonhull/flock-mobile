import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2024, 1, 1, 12);

  group('AnonymousUserExtension', () {
    group('isAnonymous', () {
      test('returns true for empty email', () {
        final user = User(
          id: 'anon-123',
          email: '',
          emailVerified: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(user.isAnonymous, true);
      });

      test('returns true for anonymous_ prefix email', () {
        final user = User(
          id: 'anon-456',
          email: 'anonymous_abc123@placeholder.local',
          emailVerified: false,
          createdAt: now,
          updatedAt: now,
        );

        expect(user.isAnonymous, true);
      });

      test('returns false for real email', () {
        final user = User(
          id: 'user-789',
          email: 'user@example.com',
          emailVerified: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(user.isAnonymous, false);
      });

      test('returns false for non-prefix anonymous_ in email', () {
        final user = User(
          id: 'user-999',
          email: 'not_anonymous_user@example.com',
          emailVerified: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(user.isAnonymous, false);
      });
    });
  });
}
