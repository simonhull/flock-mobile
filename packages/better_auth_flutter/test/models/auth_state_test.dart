import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
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

    test('AuthInitial toString', () {
      const state = AuthInitial();
      expect(state.toString(), 'AuthInitial()');
    });

    test('AuthLoading toString', () {
      const state = AuthLoading();
      expect(state.toString(), 'AuthLoading()');
    });

    test('Unauthenticated toString', () {
      const state = Unauthenticated();
      expect(state.toString(), 'Unauthenticated()');
    });

    test('Authenticated contains user and session', () {
      final state = Authenticated(user: testUser, session: testSession);

      expect(state.user, testUser);
      expect(state.session, testSession);
      expect(state.toString(), 'Authenticated(user: test@example.com)');
    });

    test('Authenticated equality', () {
      final state1 = Authenticated(user: testUser, session: testSession);
      final state2 = Authenticated(user: testUser, session: testSession);

      final differentUser = User(
        id: '456',
        email: 'other@example.com',
        emailVerified: true,
        createdAt: now,
        updatedAt: now,
      );
      final state3 = Authenticated(user: differentUser, session: testSession);

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('exhaustive switch on AuthState', () {
      String getStateName(AuthState state) => switch (state) {
            AuthInitial() => 'initial',
            AuthLoading() => 'loading',
            Authenticated() => 'authenticated',
            Unauthenticated() => 'unauthenticated',
          };

      expect(getStateName(const AuthInitial()), 'initial');
      expect(getStateName(const AuthLoading()), 'loading');
      expect(
        getStateName(Authenticated(user: testUser, session: testSession)),
        'authenticated',
      );
      expect(getStateName(const Unauthenticated()), 'unauthenticated');
    });
  });
}
