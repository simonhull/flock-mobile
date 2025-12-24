import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('MemoryStorageImpl', () {
    late MemoryStorageImpl storage;

    final now = DateTime.utc(2024, 1, 1, 12);
    final expiresAt = DateTime.now().add(const Duration(hours: 1));

    final testUser = User(
      id: '123',
      email: 'test@example.com',
      emailVerified: true,
      createdAt: now,
      updatedAt: now,
    );

    final testSession = Session(
      id: 'session-123',
      userId: '123',
      token: 'token-abc',
      expiresAt: expiresAt,
    );

    setUp(() {
      storage = MemoryStorageImpl();
    });

    group('session', () {
      test('getSession returns None when empty', () async {
        final result = await storage.getSession().run();

        switch (result) {
          case Right(value: final option):
            expect(option.isNone(), true);
          case Left():
            fail('Expected Right');
        }
      });

      test('saveSession and getSession round trip', () async {
        await storage.saveSession(testSession).run();
        final result = await storage.getSession().run();

        switch (result) {
          case Right(value: Some(:final value)):
            expect(value.id, testSession.id);
            expect(value.token, testSession.token);
          case _:
            fail('Expected Right(Some(session))');
        }
      });
    });

    group('user', () {
      test('getUser returns None when empty', () async {
        final result = await storage.getUser().run();

        switch (result) {
          case Right(value: final option):
            expect(option.isNone(), true);
          case Left():
            fail('Expected Right');
        }
      });

      test('saveUser and getUser round trip', () async {
        await storage.saveUser(testUser).run();
        final result = await storage.getUser().run();

        switch (result) {
          case Right(value: Some(:final value)):
            expect(value.id, testUser.id);
            expect(value.email, testUser.email);
          case _:
            fail('Expected Right(Some(user))');
        }
      });
    });

    group('clear', () {
      test('clears both user and session', () async {
        await storage.saveUser(testUser).run();
        await storage.saveSession(testSession).run();

        await storage.clear().run();

        final userResult = await storage.getUser().run();
        final sessionResult = await storage.getSession().run();

        switch ((userResult, sessionResult)) {
          case (
              Right(value: final userOpt),
              Right(value: final sessionOpt)
            ):
            expect(userOpt.isNone(), true);
            expect(sessionOpt.isNone(), true);
          case _:
            fail('Expected both to be Right(None)');
        }
      });
    });
  });
}
