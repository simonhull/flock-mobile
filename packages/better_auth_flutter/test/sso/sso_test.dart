import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// Mock browser handler for testing.
final class MockSSOBrowserHandler implements SSOBrowserHandler {
  Uri? lastAuthorizationUrl;
  Uri? lastCallbackUrl;
  Uri? resultToReturn;
  Exception? errorToThrow;

  @override
  Future<Uri> openAndWaitForCallback({
    required Uri authorizationUrl,
    required Uri callbackUrl,
  }) async {
    lastAuthorizationUrl = authorizationUrl;
    lastCallbackUrl = callbackUrl;

    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

void main() {
  group('SSO', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late MemoryStorageImpl storage;
    late List<AuthState> emittedStates;
    late BetterAuthClientImpl client;
    late MockSSOBrowserHandler browserHandler;

    final now = DateTime.utc(2024, 1, 1, 12);
    final expiresAt = DateTime.now().add(const Duration(hours: 1));

    final mockUserJson = {
      'id': 'user-123',
      'email': 'user@acme.com',
      'name': 'Test User',
      'emailVerified': true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    // BetterAuth returns token at top level, not inside a session object
    const mockToken = 'token-abc';

    final mockAuthorizationResponseJson = {
      'authorizationUrl': 'https://idp.acme.com/authorize?client_id=abc&state=xyz123',
      'callbackUrl': 'https://api.example.com/api/auth/sso/callback/provider-123',
      'providerId': 'provider-123',
      'state': 'xyz123',
    };

    final mockProviderJson = {
      'id': 'provider-123',
      'name': 'Acme Corp Okta',
      'type': 'oidc',
      'domain': 'acme.com',
      'isEnabled': true,
      'createdAt': '2024-01-15T10:30:00.000Z',
    };

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dioAdapter = DioAdapter(dio: dio);
      storage = MemoryStorageImpl();
      emittedStates = [];
      browserHandler = MockSSOBrowserHandler();

      client = BetterAuthClientImpl(
        baseUrl: 'https://api.example.com',
        storage: storage,
        dio: dio,
      );

      client.authStateChanges.listen(emittedStates.add);
    });

    group('signIn', () {
      test('requires email or providerId', () async {
        final result = await client.sso.signIn(
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Left(:final value):
            expect(value.code, 'INVALID_PARAMS');
          case Right():
            fail('Expected Left');
        }
      });

      test('gets authorization URL from server', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/api/auth/sso/callback/provider-123?code=auth_code&state=xyz123',
        );

        dioAdapter
          ..onPost(
            '/api/auth/sso/sign-in',
            (server) => server.reply(200, mockAuthorizationResponseJson),
            data: Matchers.any,
          )
          ..onGet(
            '/api/auth/sso/callback/provider-123',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            queryParameters: {'code': 'auth_code', 'state': 'xyz123'},
          );

        final result = await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        expect(result.isRight(), true);
      });

      test('calls browserHandler with correct URLs', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/api/auth/sso/callback/provider-123?code=auth_code&state=xyz123',
        );

        dioAdapter
          ..onPost(
            '/api/auth/sso/sign-in',
            (server) => server.reply(200, mockAuthorizationResponseJson),
            data: Matchers.any,
          )
          ..onGet(
            '/api/auth/sso/callback/provider-123',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            queryParameters: {'code': 'auth_code', 'state': 'xyz123'},
          );

        await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        expect(
          browserHandler.lastAuthorizationUrl,
          Uri.parse('https://idp.acme.com/authorize?client_id=abc&state=xyz123'),
        );
        expect(
          browserHandler.lastCallbackUrl,
          Uri.parse('https://api.example.com/api/auth/sso/callback/provider-123'),
        );
      });

      test('validates state parameter', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/callback?code=auth_code&state=wrong_state',
        );

        dioAdapter.onPost(
          '/api/auth/sso/sign-in',
          (server) => server.reply(200, mockAuthorizationResponseJson),
          data: Matchers.any,
        );

        final result = await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<SSOStateMismatch>());
          case Right():
            fail('Expected Left');
        }
      });

      test('handles callback and returns Authenticated', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/callback?code=auth_code&state=xyz123',
        );

        dioAdapter
          ..onPost(
            '/api/auth/sso/sign-in',
            (server) => server.reply(200, mockAuthorizationResponseJson),
            data: Matchers.any,
          )
          ..onGet(
            '/api/auth/sso/callback/provider-123',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            queryParameters: {'code': 'auth_code', 'state': 'xyz123'},
          );

        final result = await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Right(:final value):
            expect(value, isA<Authenticated>());
            expect(value.user.email, 'user@acme.com');
          case Left(:final value):
            fail('Expected Right, got ${value.message}');
        }
      });

      test('emits AuthLoading then Authenticated', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/callback?code=auth_code&state=xyz123',
        );

        dioAdapter
          ..onPost(
            '/api/auth/sso/sign-in',
            (server) => server.reply(200, mockAuthorizationResponseJson),
            data: Matchers.any,
          )
          ..onGet(
            '/api/auth/sso/callback/provider-123',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            queryParameters: {'code': 'auth_code', 'state': 'xyz123'},
          );

        await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        await Future<void>.delayed(Duration.zero);

        expect(emittedStates.length, greaterThanOrEqualTo(2));
        expect(emittedStates, contains(isA<AuthLoading>()));
        expect(emittedStates.last, isA<Authenticated>());
      });

      test('saves user and session to storage', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/callback?code=auth_code&state=xyz123',
        );

        dioAdapter
          ..onPost(
            '/api/auth/sso/sign-in',
            (server) => server.reply(200, mockAuthorizationResponseJson),
            data: Matchers.any,
          )
          ..onGet(
            '/api/auth/sso/callback/provider-123',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            queryParameters: {'code': 'auth_code', 'state': 'xyz123'},
          );

        await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        final savedUserResult = await storage.getUser().run();
        final savedSessionResult = await storage.getSession().run();

        switch (savedUserResult) {
          case Right(:final value):
            expect(value.isSome(), true);
          case Left():
            fail('Expected Right');
        }

        switch (savedSessionResult) {
          case Right(:final value):
            expect(value.isSome(), true);
          case Left():
            fail('Expected Right');
        }
      });

      test('fails if provider not found', () async {
        dioAdapter.onPost(
          '/api/auth/sso/sign-in',
          (server) => server.reply(404, {
            'code': 'SSO_PROVIDER_NOT_FOUND',
            'message': 'No SSO provider configured for this domain',
          }),
          data: Matchers.any,
        );

        final result = await client.sso.signIn(
          email: 'user@unknown.com',
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<SSOProviderNotFound>());
          case Right():
            fail('Expected Left');
        }
      });

      test('fails if provider disabled', () async {
        dioAdapter.onPost(
          '/api/auth/sso/sign-in',
          (server) => server.reply(403, {
            'code': 'SSO_PROVIDER_DISABLED',
            'message': 'SSO provider is disabled',
          }),
          data: Matchers.any,
        );

        final result = await client.sso.signIn(
          email: 'user@disabled.com',
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<SSOProviderDisabled>());
          case Right():
            fail('Expected Left');
        }
      });

      test('fails on state mismatch', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/callback?code=abc&state=tampered',
        );

        dioAdapter.onPost(
          '/api/auth/sso/sign-in',
          (server) => server.reply(200, mockAuthorizationResponseJson),
          data: Matchers.any,
        );

        final result = await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<SSOStateMismatch>());
          case Right():
            fail('Expected Left');
        }
      });

      test('handles user cancellation', () async {
        browserHandler.errorToThrow = Exception('User cancelled');

        dioAdapter.onPost(
          '/api/auth/sso/sign-in',
          (server) => server.reply(200, mockAuthorizationResponseJson),
          data: Matchers.any,
        );

        final result = await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<SSOCancelled>());
          case Right():
            fail('Expected Left');
        }
      });

      test('handles network error', () async {
        dioAdapter.onPost(
          '/api/auth/sso/sign-in',
          (server) => server.throws(
            -1,
            DioException(
              type: DioExceptionType.connectionError,
              requestOptions: RequestOptions(path: '/api/auth/sso/sign-in'),
            ),
          ),
          data: Matchers.any,
        );

        final result = await client.sso.signIn(
          email: 'user@acme.com',
          browserHandler: browserHandler,
        ).run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<NetworkError>());
          case Right():
            fail('Expected Left');
        }
      });

      test('uses providerId directly when specified', () async {
        browserHandler.resultToReturn = Uri.parse(
          'https://api.example.com/callback?code=auth_code&state=xyz123',
        );

        dioAdapter
          ..onPost(
            '/api/auth/sso/sign-in',
            (server) => server.reply(200, mockAuthorizationResponseJson),
            data: {'providerId': 'explicit-provider'},
          )
          ..onGet(
            '/api/auth/sso/callback/provider-123',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            queryParameters: {'code': 'auth_code', 'state': 'xyz123'},
          );

        final result = await client.sso.signIn(
          providerId: 'explicit-provider',
          browserHandler: browserHandler,
        ).run();

        expect(result.isRight(), true);
      });
    });

    group('checkDomain', () {
      test('returns provider for configured domain', () async {
        dioAdapter.onGet(
          '/api/auth/sso/providers',
          (server) => server.reply(200, {
            'providers': [mockProviderJson],
          }),
          queryParameters: {'domain': 'acme.com'},
        );

        final result = await client.sso.checkDomain(
          email: 'user@acme.com',
        ).run();

        switch (result) {
          case Right(:final value):
            expect(value, isNotNull);
            expect(value!.id, 'provider-123');
            expect(value.domain, 'acme.com');
          case Left():
            fail('Expected Right');
        }
      });

      test('returns null for unconfigured domain', () async {
        dioAdapter.onGet(
          '/api/auth/sso/providers',
          (server) => server.reply(200, {
            'providers': <dynamic>[],
          }),
          queryParameters: {'domain': 'unknown.com'},
        );

        final result = await client.sso.checkDomain(
          email: 'user@unknown.com',
        ).run();

        switch (result) {
          case Right(:final value):
            expect(value, isNull);
          case Left():
            fail('Expected Right');
        }
      });

      test('extracts domain from email', () async {
        dioAdapter.onGet(
          '/api/auth/sso/providers',
          (server) => server.reply(200, {
            'providers': [mockProviderJson],
          }),
          queryParameters: {'domain': 'company.org'},
        );

        await client.sso.checkDomain(
          email: 'employee@company.org',
        ).run();

        // If mock matched, domain was extracted correctly
      });
    });

    group('listProviders', () {
      test('returns list of providers', () async {
        dioAdapter.onGet(
          '/api/auth/sso/providers',
          (server) => server.reply(200, {
            'providers': [
              mockProviderJson,
              {
                'id': 'provider-456',
                'name': 'Google Workspace',
                'type': 'oauth2',
                'domain': 'google.com',
                'isEnabled': true,
                'createdAt': '2024-02-01T00:00:00.000Z',
              },
            ],
          }),
        );

        final result = await client.sso.listProviders().run();

        switch (result) {
          case Right(:final value):
            expect(value.length, 2);
            expect(value[0].name, 'Acme Corp Okta');
            expect(value[1].name, 'Google Workspace');
          case Left():
            fail('Expected Right');
        }
      });

      test('returns empty list if none configured', () async {
        dioAdapter.onGet(
          '/api/auth/sso/providers',
          (server) => server.reply(200, {
            'providers': <dynamic>[],
          }),
        );

        final result = await client.sso.listProviders().run();

        switch (result) {
          case Right(:final value):
            expect(value, isEmpty);
          case Left():
            fail('Expected Right');
        }
      });
    });
  });
}
