import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';

class MockOAuthProvider extends Mock implements OAuthProvider {}

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late BetterAuthClientImpl client;
  late MemoryStorageImpl storage;
  late Anonymous anonymous;

  final mockAnonAuthResponse = {
    'user': {
      'id': 'anon-user-123',
      'email': '',
      'name': null,
      'emailVerified': false,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    },
    'session': {
      'id': 'session-456',
      'token': 'anon-token-abc',
      'userId': 'anon-user-123',
      'expiresAt':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    },
  };

  final mockLinkedAuthResponse = {
    'user': {
      'id': 'anon-user-123',
      'email': 'upgraded@example.com',
      'name': 'New User',
      'emailVerified': false,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T12:00:00.000Z',
    },
    'session': {
      'id': 'session-789',
      'token': 'linked-token-xyz',
      'userId': 'anon-user-123',
      'expiresAt':
          DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'createdAt': '2024-01-01T12:00:00.000Z',
      'updatedAt': '2024-01-01T12:00:00.000Z',
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
    anonymous = Anonymous(client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('Anonymous.signIn', () {
    test('creates anonymous user and returns Authenticated', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/sign-in',
        (server) => server.reply(200, mockAnonAuthResponse),
        data: <String, dynamic>{},
      );

      final result = await anonymous.signIn().run();

      expect(result.isRight(), true);
      switch (result) {
        case Right(:final value):
          expect(value, isA<Authenticated>());
          expect(value.user.id, 'anon-user-123');
          expect(value.user.email, '');
          expect(value.user.isAnonymous, true);
        case Left():
          fail('Expected Right');
      }
    });

    test('emits AuthLoading then Authenticated', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/sign-in',
        (server) => server.reply(200, mockAnonAuthResponse),
        data: <String, dynamic>{},
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await anonymous.signIn().run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('persists user and session to storage', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/sign-in',
        (server) => server.reply(200, mockAnonAuthResponse),
        data: <String, dynamic>{},
      );

      await anonymous.signIn().run();

      final userResult = await storage.getUser().run();
      final sessionResult = await storage.getSession().run();

      expect(userResult.isRight(), true);
      expect(sessionResult.isRight(), true);

      switch (userResult) {
        case Right(:final value):
          switch (value) {
            case Some(:final value):
              expect(value.id, 'anon-user-123');
            case None():
              fail('Expected Some');
          }
        case Left():
          fail('Expected Right');
      }
    });

    test('returns NetworkError on connection failure', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/sign-in',
        (server) => server.throws(
          0,
          DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(path: '/api/auth/anonymous/sign-in'),
          ),
        ),
        data: <String, dynamic>{},
      );

      final result = await anonymous.signIn().run();

      expect(result.isLeft(), true);
      switch (result) {
        case Left(:final value):
          expect(value, isA<NetworkError>());
        case Right():
          fail('Expected Left');
      }
    });

    test('emits Unauthenticated on failure', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/sign-in',
        (server) => server.reply(500, {'message': 'Server error'}),
        data: <String, dynamic>{},
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await anonymous.signIn().run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<Unauthenticated>()));
    });
  });

  group('Anonymous.linkEmail', () {
    test('links email and returns Authenticated', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(200, mockLinkedAuthResponse),
        data: {
          'email': 'upgraded@example.com',
          'password': 'securepassword123',
        },
      );

      final result = await anonymous
          .linkEmail(
            email: 'upgraded@example.com',
            password: 'securepassword123',
          )
          .run();

      expect(result.isRight(), true);
      switch (result) {
        case Right(:final value):
          expect(value, isA<Authenticated>());
          expect(value.user.id, 'anon-user-123');
          expect(value.user.email, 'upgraded@example.com');
          expect(value.user.isAnonymous, false);
        case Left():
          fail('Expected Right');
      }
    });

    test('preserves user ID after linking', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(200, mockLinkedAuthResponse),
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
        },
      );

      final result = await anonymous
          .linkEmail(
            email: 'upgraded@example.com',
            password: 'password',
          )
          .run();

      switch (result) {
        case Right(:final value):
          expect(value.user.id, 'anon-user-123');
        case Left():
          fail('Expected Right');
      }
    });

    test('sends name when provided', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(200, mockLinkedAuthResponse),
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
          'name': 'John Doe',
        },
      );

      final result = await anonymous
          .linkEmail(
            email: 'upgraded@example.com',
            password: 'password',
            name: 'John Doe',
          )
          .run();

      expect(result.isRight(), true);
    });

    test('emits AuthLoading then Authenticated', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(200, mockLinkedAuthResponse),
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
        },
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await anonymous
          .linkEmail(
            email: 'upgraded@example.com',
            password: 'password',
          )
          .run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('returns NotAnonymous when user is not anonymous', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(400, {
          'message': 'Current user is not anonymous',
          'code': 'NOT_ANONYMOUS',
        }),
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
        },
      );

      final result = await anonymous
          .linkEmail(
            email: 'upgraded@example.com',
            password: 'password',
          )
          .run();

      expect(result.isLeft(), true);
      switch (result) {
        case Left(:final value):
          expect(value, isA<NotAnonymous>());
        case Right():
          fail('Expected Left');
      }
    });

    test('returns UserAlreadyExists when email is taken', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(409, {
          'message': 'Email already in use',
          'code': 'EMAIL_ALREADY_EXISTS',
        }),
        data: {
          'email': 'taken@example.com',
          'password': 'password',
        },
      );

      final result = await anonymous
          .linkEmail(
            email: 'taken@example.com',
            password: 'password',
          )
          .run();

      expect(result.isLeft(), true);
      switch (result) {
        case Left(:final value):
          expect(value, isA<UserAlreadyExists>());
        case Right():
          fail('Expected Left');
      }
    });

    test('returns AccountAlreadyLinked when already linked', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(400, {
          'message': 'Account already linked',
          'code': 'ACCOUNT_ALREADY_LINKED',
        }),
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
        },
      );

      final result = await anonymous
          .linkEmail(
            email: 'upgraded@example.com',
            password: 'password',
          )
          .run();

      expect(result.isLeft(), true);
      switch (result) {
        case Left(:final value):
          expect(value, isA<AccountAlreadyLinked>());
        case Right():
          fail('Expected Left');
      }
    });

    test('emits Unauthenticated on failure', () async {
      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(400, {
          'message': 'Not anonymous',
          'code': 'NOT_ANONYMOUS',
        }),
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
        },
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await anonymous
          .linkEmail(
            email: 'upgraded@example.com',
            password: 'password',
          )
          .run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<Unauthenticated>()));
    });
  });

  group('Anonymous.linkSocial', () {
    late MockOAuthProvider mockProvider;

    setUp(() {
      mockProvider = MockOAuthProvider();
      when(() => mockProvider.providerId).thenReturn('google');
    });

    test('links social provider to anonymous account', () async {
      when(() => mockProvider.authenticate()).thenAnswer(
        (_) async => const OAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(200, mockLinkedAuthResponse),
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      final result = await anonymous.linkSocial(provider: mockProvider).run();

      expect(result.isRight(), true);
      switch (result) {
        case Right(:final value):
          expect(value, isA<Authenticated>());
          expect(value.user.email, 'upgraded@example.com');
        case Left():
          fail('Expected Right');
      }
    });

    test('calls provider.authenticate()', () async {
      when(() => mockProvider.authenticate()).thenAnswer(
        (_) async => const OAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(200, mockLinkedAuthResponse),
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      await anonymous.linkSocial(provider: mockProvider).run();

      verify(() => mockProvider.authenticate()).called(1);
    });

    test('returns NotAnonymous when user is not anonymous', () async {
      when(() => mockProvider.authenticate()).thenAnswer(
        (_) async => const OAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(400, {
          'message': 'Current user is not anonymous',
          'code': 'NOT_ANONYMOUS',
        }),
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      final result = await anonymous.linkSocial(provider: mockProvider).run();

      expect(result.isLeft(), true);
      switch (result) {
        case Left(:final value):
          expect(value, isA<NotAnonymous>());
        case Right():
          fail('Expected Left');
      }
    });

    test('returns AccountAlreadyLinked when already linked', () async {
      when(() => mockProvider.authenticate()).thenAnswer(
        (_) async => const OAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(400, {
          'message': 'Account already linked',
          'code': 'ACCOUNT_ALREADY_LINKED',
        }),
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      final result = await anonymous.linkSocial(provider: mockProvider).run();

      expect(result.isLeft(), true);
      switch (result) {
        case Left(:final value):
          expect(value, isA<AccountAlreadyLinked>());
        case Right():
          fail('Expected Left');
      }
    });

    test('returns OAuthCancelled when user cancels', () async {
      when(() => mockProvider.authenticate()).thenThrow(const OAuthCancelled());

      final result = await anonymous.linkSocial(provider: mockProvider).run();

      expect(result.isLeft(), true);
      switch (result) {
        case Left(:final value):
          expect(value, isA<OAuthCancelled>());
        case Right():
          fail('Expected Left');
      }
    });

    test('emits AuthLoading then Authenticated on success', () async {
      when(() => mockProvider.authenticate()).thenAnswer(
        (_) async => const OAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(200, mockLinkedAuthResponse),
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await anonymous.linkSocial(provider: mockProvider).run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('emits Unauthenticated on failure', () async {
      when(() => mockProvider.authenticate()).thenAnswer(
        (_) async => const OAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/anonymous/link',
        (server) => server.reply(400, {
          'message': 'Not anonymous',
          'code': 'NOT_ANONYMOUS',
        }),
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await anonymous.linkSocial(provider: mockProvider).run();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<Unauthenticated>()));
    });
  });
}
