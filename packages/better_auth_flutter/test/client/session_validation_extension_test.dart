import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBetterAuthClient extends Mock implements BetterAuthClient {}

void main() {
  group('SessionValidationExtension', () {
    late MockBetterAuthClient client;

    setUp(() {
      client = MockBetterAuthClient();
    });

    group('validateSession', () {
      test('returns current session when valid and not expiring', () async {
        final session = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'token-abc',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: session,
          ),
        );

        final result = await client.validateSession().run();

        switch (result) {
          case Right(:final value):
            expect(value.id, session.id);
          case Left():
            fail('Expected Right, got Left');
        }

        verifyNever(() => client.getSession());
      });

      test('refreshes session when expiring soon', () async {
        final expiringSession = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'old-token',
          expiresAt: DateTime.now().add(const Duration(minutes: 2)),
        );

        final refreshedSession = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'new-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: expiringSession,
          ),
        );

        when(() => client.getSession()).thenReturn(
          TaskEither.of(refreshedSession),
        );

        final result = await client.validateSession().run();

        switch (result) {
          case Right(:final value):
            expect(value.token, 'new-token');
          case Left():
            fail('Expected Right, got Left');
        }

        verify(() => client.getSession()).called(1);
      });

      test('returns error when not authenticated', () async {
        when(() => client.currentState).thenReturn(const Unauthenticated());

        final result = await client.validateSession().run();

        switch (result) {
          case Right():
            fail('Expected Left, got Right');
          case Left(:final value):
            expect(value, isA<NotAuthenticated>());
        }
      });

      test('returns error when in initial state', () async {
        when(() => client.currentState).thenReturn(const AuthInitial());

        final result = await client.validateSession().run();

        switch (result) {
          case Right():
            fail('Expected Left, got Right');
          case Left(:final value):
            expect(value, isA<NotAuthenticated>());
        }
      });

      test('respects custom threshold', () async {
        final session = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'token-abc',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        );

        final refreshedSession = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'new-token',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: session,
          ),
        );

        when(() => client.getSession()).thenReturn(
          TaskEither.of(refreshedSession),
        );

        // With default 5 minute threshold, should not refresh
        await client.validateSession().run();
        verifyNever(() => client.getSession());

        // With 15 minute threshold, should refresh
        await client.validateSession(
          threshold: const Duration(minutes: 15),
        ).run();
        verify(() => client.getSession()).called(1);
      });
    });

    group('hasValidSession', () {
      test('returns true for valid non-expiring session', () {
        final session = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'token-abc',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: session,
          ),
        );

        expect(client.hasValidSession, true);
      });

      test('returns false for expired session', () {
        final session = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'token-abc',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: session,
          ),
        );

        expect(client.hasValidSession, false);
      });

      test('returns false for expiring session', () {
        final session = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'token-abc',
          expiresAt: DateTime.now().add(const Duration(minutes: 2)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: session,
          ),
        );

        expect(client.hasValidSession, false);
      });

      test('returns false when not authenticated', () {
        when(() => client.currentState).thenReturn(const Unauthenticated());
        expect(client.hasValidSession, false);
      });

      test('returns false when loading', () {
        when(() => client.currentState).thenReturn(const AuthLoading());
        expect(client.hasValidSession, false);
      });
    });

    group('timeUntilExpiry', () {
      test('returns duration for authenticated session', () {
        final session = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'token-abc',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: session,
          ),
        );

        final duration = client.timeUntilExpiry;
        expect(duration, isNotNull);
        expect(duration!.inMinutes, greaterThan(55));
      });

      test('returns zero for expired session', () {
        final session = Session(
          id: 'session-123',
          userId: 'user-456',
          token: 'token-abc',
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => client.currentState).thenReturn(
          Authenticated(
            user: User(
              id: 'user-456',
              email: 'test@example.com',
              name: 'Test',
              emailVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            session: session,
          ),
        );

        expect(client.timeUntilExpiry, Duration.zero);
      });

      test('returns null when not authenticated', () {
        when(() => client.currentState).thenReturn(const Unauthenticated());
        expect(client.timeUntilExpiry, isNull);
      });

      test('returns null when loading', () {
        when(() => client.currentState).thenReturn(const AuthLoading());
        expect(client.timeUntilExpiry, isNull);
      });
    });
  });
}
