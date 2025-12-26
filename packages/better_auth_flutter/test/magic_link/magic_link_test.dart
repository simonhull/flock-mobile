import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late BetterAuthClientImpl client;
  late MemoryStorageImpl storage;
  late MagicLink magicLink;

  final mockAuthResponse = {
    'user': {
      'id': 'user-123',
      'email': 'test@example.com',
      'name': 'Test User',
      'emailVerified': true,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    },
    'session': {
      'id': 'session-123',
      'token': 'token-abc',
      'userId': 'user-123',
      'expiresAt':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    },
  };

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dioAdapter = DioAdapter(dio: dio);
    storage = MemoryStorageImpl();
    client = BetterAuthClientImpl(
      baseUrl: 'https://api.example.com',
      storage: storage,
      dio: dio,
    );
    magicLink = MagicLink(client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('MagicLink.send', () {
    test('sends magic link and returns expiry info', () async {
      dioAdapter.onPost(
        '/api/auth/magic-link/send',
        (server) => server.reply(200, {
          'email': 'user@example.com',
          'expiresAt': '2024-01-15T12:30:00.000Z',
        }),
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
      dioAdapter.onPost(
        '/api/auth/magic-link/send',
        (server) => server.reply(200, {
          'email': 'user@example.com',
          'expiresAt': '2024-01-15T12:30:00.000Z',
        }),
        data: {'email': 'user@example.com', 'createUser': false},
      );

      final result = await magicLink
          .send(email: 'user@example.com', createUser: false)
          .run();

      expect(result.isRight(), true);
    });

    test('sends with custom callbackURL', () async {
      dioAdapter.onPost(
        '/api/auth/magic-link/send',
        (server) => server.reply(200, {
          'email': 'user@example.com',
          'expiresAt': '2024-01-15T12:30:00.000Z',
        }),
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
      dioAdapter.onPost(
        '/api/auth/magic-link/send',
        (server) => server.reply(404, {
          'message': 'User not found',
          'code': 'USER_NOT_FOUND',
        }),
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
      dioAdapter.onGet(
        '/api/auth/magic-link/verify',
        (server) => server.reply(200, mockAuthResponse),
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
      dioAdapter.onGet(
        '/api/auth/magic-link/verify',
        (server) => server.reply(200, mockAuthResponse),
        queryParameters: {'token': 'valid-token-123'},
      );

      await magicLink.verify(token: 'valid-token-123').run();

      final userResult = await storage.getUser().run();
      final sessionResult = await storage.getSession().run();

      expect(userResult.isRight(), true);
      expect(sessionResult.isRight(), true);
    });

    test('emits AuthLoading then Authenticated', () async {
      dioAdapter.onGet(
        '/api/auth/magic-link/verify',
        (server) => server.reply(200, mockAuthResponse),
        queryParameters: {'token': 'valid-token-123'},
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await magicLink.verify(token: 'valid-token-123').run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('returns MagicLinkExpired on expired token', () async {
      dioAdapter.onGet(
        '/api/auth/magic-link/verify',
        (server) => server.reply(400, {
          'message': 'Token expired',
          'code': 'MAGIC_LINK_EXPIRED',
        }),
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
      dioAdapter.onGet(
        '/api/auth/magic-link/verify',
        (server) => server.reply(400, {
          'message': 'Invalid token',
          'code': 'INVALID_TOKEN',
        }),
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
      dioAdapter.onGet(
        '/api/auth/magic-link/verify',
        (server) => server.reply(400, {
          'message': 'Token already used',
          'code': 'MAGIC_LINK_USED',
        }),
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
      dioAdapter.onGet(
        '/api/auth/magic-link/verify',
        (server) => server.reply(400, {
          'message': 'Invalid token',
          'code': 'INVALID_TOKEN',
        }),
        queryParameters: {'token': 'invalid-token'},
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await magicLink.verify(token: 'invalid-token').run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<Unauthenticated>()));
    });
  });
}
