import 'package:better_auth_flutter/src/client/better_auth_client_impl.dart';
import 'package:better_auth_flutter/src/client/social_auth_extension.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/social/oauth_credential.dart';
import 'package:better_auth_flutter/src/social/oauth_provider.dart';
import 'package:better_auth_flutter/src/storage/memory_storage_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// Mock provider for testing.
final class MockOAuthProvider implements OAuthProvider {
  MockOAuthProvider({
    this.providerId = 'mock',
    this.credential,
    this.error,
  });

  @override
  final String providerId;

  final OAuthCredential? credential;
  final AuthError? error;

  @override
  Future<OAuthCredential> authenticate() async {
    if (error != null) throw error!;
    return credential!;
  }
}

void main() {
  group('signInWithProvider', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late BetterAuthClientImpl client;
    late MemoryStorageImpl storage;

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
    });

    tearDown(() async {
      await client.dispose();
    });

    test('sends correct payload to server with idToken only', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        credential: const OAuthCredential(idToken: 'google-id-token'),
      );

      dioAdapter.onPost(
        '/api/auth/sign-in/social',
        (server) => server.reply(200, mockAuthResponse),
        data: {
          'provider': 'google',
          'idToken': {
            'token': 'google-id-token',
          },
        },
      );

      final result = await client.signInWithProvider(provider).run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (state) {
          expect(state, isA<Authenticated>());
          expect(state.user.email, 'test@example.com');
        },
      );
    });

    test('sends accessToken when provided', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        credential: const OAuthCredential(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/sign-in/social',
        (server) => server.reply(200, mockAuthResponse),
        data: {
          'provider': 'google',
          'idToken': {
            'token': 'google-id-token',
            'accessToken': 'google-access-token',
          },
        },
      );

      final result = await client.signInWithProvider(provider).run();

      expect(result.isRight(), true);
    });

    test('sends nonce when provided (Apple)', () async {
      final provider = MockOAuthProvider(
        providerId: 'apple',
        credential: const OAuthCredential(
          idToken: 'apple-id-token',
          nonce: 'apple-nonce-123',
        ),
      );

      dioAdapter.onPost(
        '/api/auth/sign-in/social',
        (server) => server.reply(200, mockAuthResponse),
        data: {
          'provider': 'apple',
          'idToken': {
            'token': 'apple-id-token',
            'nonce': 'apple-nonce-123',
          },
        },
      );

      final result = await client.signInWithProvider(provider).run();

      expect(result.isRight(), true);
    });

    test('returns OAuthCancelled when user cancels', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        error: const OAuthCancelled(),
      );

      final result = await client.signInWithProvider(provider).run();

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, isA<OAuthCancelled>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns OAuthProviderError on SDK failure', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        error: const OAuthProviderError(
          provider: 'Google',
          details: 'Network error',
        ),
      );

      final result = await client.signInWithProvider(provider).run();

      expect(result.isLeft(), true);
      result.fold(
        (error) {
          expect(error, isA<OAuthProviderError>());
          expect((error as OAuthProviderError).provider, 'Google');
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns error on server rejection', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        credential: const OAuthCredential(idToken: 'invalid-token'),
      );

      dioAdapter.onPost(
        '/api/auth/sign-in/social',
        (server) => server.reply(401, {'message': 'Invalid token'}),
        data: {
          'provider': 'google',
          'idToken': {'token': 'invalid-token'},
        },
      );

      final result = await client.signInWithProvider(provider).run();

      expect(result.isLeft(), true);
    });

    test('updates auth state on success', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        credential: const OAuthCredential(idToken: 'valid-token'),
      );

      dioAdapter.onPost(
        '/api/auth/sign-in/social',
        (server) => server.reply(200, mockAuthResponse),
        data: {
          'provider': 'google',
          'idToken': {'token': 'valid-token'},
        },
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await client.signInWithProvider(provider).run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('persists user and session on success', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        credential: const OAuthCredential(idToken: 'valid-token'),
      );

      dioAdapter.onPost(
        '/api/auth/sign-in/social',
        (server) => server.reply(200, mockAuthResponse),
        data: {
          'provider': 'google',
          'idToken': {'token': 'valid-token'},
        },
      );

      await client.signInWithProvider(provider).run();

      final userResult = await storage.getUser().run();
      final sessionResult = await storage.getSession().run();

      expect(userResult.isRight(), true);
      expect(sessionResult.isRight(), true);
    });
  });
}
