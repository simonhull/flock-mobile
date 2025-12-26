import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_harness.dart';

void main() {
  final harness = AuthTestHarness();
  late MagicLink magicLink;

  setUp(() {
    harness.setUp();
    magicLink = MagicLink(harness.pluginContext);
  });

  tearDown(harness.tearDown);

  group('MagicLink.send', () {
    test('sends magic link and returns expiry info', () async {
      harness.onPost(
        '/api/auth/magic-link/send',
        AuthFixtures.magicLinkSent(
          email: 'user@example.com',
          expiresAt: DateTime.utc(2024, 1, 15, 12, 30),
        ),
        data: {'email': 'user@example.com', 'createUser': true},
      );

      final result = await magicLink.send(email: 'user@example.com').run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (sent) {
          expect(sent.email, 'user@example.com');
          expect(sent.expiresAt, DateTime.utc(2024, 1, 15, 12, 30));
        },
      );
    });

    test('sends with createUser false', () async {
      harness.onPost(
        '/api/auth/magic-link/send',
        AuthFixtures.magicLinkSent(email: 'user@example.com'),
        data: {'email': 'user@example.com', 'createUser': false},
      );

      final result = await magicLink
          .send(email: 'user@example.com', createUser: false)
          .run();

      expect(result.isRight(), true);
    });

    test('sends with custom callbackURL', () async {
      harness.onPost(
        '/api/auth/magic-link/send',
        AuthFixtures.magicLinkSent(email: 'user@example.com'),
        data: {
          'email': 'user@example.com',
          'createUser': true,
          'callbackURL': 'myapp://auth/magic',
        },
      );

      final result = await magicLink
          .send(email: 'user@example.com', callbackURL: 'myapp://auth/magic')
          .run();

      expect(result.isRight(), true);
    });

    test('returns error when user not found and createUser false', () async {
      harness.onPost(
        '/api/auth/magic-link/send',
        AuthFixtures.error(message: 'User not found', code: 'USER_NOT_FOUND'),
        statusCode: 404,
        data: {'email': 'unknown@example.com', 'createUser': false},
      );

      final result = await magicLink
          .send(email: 'unknown@example.com', createUser: false)
          .run();

      expect(result.isLeft(), true);
    });
  });

  group('MagicLink.verify', () {
    test('verifies token and returns Authenticated', () async {
      harness.onGet(
        '/api/auth/magic-link/verify',
        AuthFixtures.authResponse(),
        queryParameters: {'token': 'valid-token-123'},
      );

      final result = await magicLink.verify(token: 'valid-token-123').run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (state) {
          expect(state, isA<Authenticated>());
          expect(state.user.email, 'test@example.com');
        },
      );
    });

    test('persists user and session on success', () async {
      harness.onGet(
        '/api/auth/magic-link/verify',
        AuthFixtures.authResponse(),
        queryParameters: {'token': 'valid-token-123'},
      );

      await magicLink.verify(token: 'valid-token-123').run();

      final userResult = await harness.storage.getUser().run();
      final sessionResult = await harness.storage.getSession().run();

      expect(userResult.isRight(), true);
      expect(sessionResult.isRight(), true);
    });

    test('emits AuthLoading then Authenticated', () async {
      harness.onGet(
        '/api/auth/magic-link/verify',
        AuthFixtures.authResponse(),
        queryParameters: {'token': 'valid-token-123'},
      );

      final states = await harness.collectStates(
        () => magicLink.verify(token: 'valid-token-123').run(),
      );

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('returns MagicLinkExpired on expired token', () async {
      harness.onGet(
        '/api/auth/magic-link/verify',
        AuthFixtures.error(message: 'Token expired', code: 'MAGIC_LINK_EXPIRED'),
        statusCode: 400,
        queryParameters: {'token': 'expired-token'},
      );

      final result = await magicLink.verify(token: 'expired-token').run();

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, isA<MagicLinkExpired>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns MagicLinkInvalid on invalid token', () async {
      harness.onGet(
        '/api/auth/magic-link/verify',
        AuthFixtures.error(message: 'Invalid token', code: 'INVALID_TOKEN'),
        statusCode: 400,
        queryParameters: {'token': 'invalid-token'},
      );

      final result = await magicLink.verify(token: 'invalid-token').run();

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, isA<MagicLinkInvalid>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns MagicLinkAlreadyUsed on used token', () async {
      harness.onGet(
        '/api/auth/magic-link/verify',
        AuthFixtures.error(message: 'Token already used', code: 'MAGIC_LINK_USED'),
        statusCode: 400,
        queryParameters: {'token': 'used-token'},
      );

      final result = await magicLink.verify(token: 'used-token').run();

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, isA<MagicLinkAlreadyUsed>()),
        (_) => fail('Expected Left'),
      );
    });

    test('emits Unauthenticated on failure', () async {
      harness.onGet(
        '/api/auth/magic-link/verify',
        AuthFixtures.error(message: 'Invalid token', code: 'INVALID_TOKEN'),
        statusCode: 400,
        queryParameters: {'token': 'invalid-token'},
      );

      final states = await harness.collectStates(
        () => magicLink.verify(token: 'invalid-token').run(),
      );

      expect(states, contains(isA<Unauthenticated>()));
    });
  });
}
