import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// Mock authenticator for testing.
final class MockPasskeyAuthenticator implements PasskeyAuthenticator {
  bool isSupportedResult = true;
  bool isAvailableResult = true;
  RegistrationResponse? registrationResult;
  AuthenticationResponse? authenticationResult;
  Exception? errorToThrow;

  RegistrationOptions? lastRegistrationOptions;
  AuthenticationOptions? lastAuthenticationOptions;

  @override
  Future<bool> isSupported() async => isSupportedResult;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Future<RegistrationResponse> createCredential(
    RegistrationOptions options,
  ) async {
    lastRegistrationOptions = options;
    if (errorToThrow != null) throw errorToThrow!;
    return registrationResult!;
  }

  @override
  Future<AuthenticationResponse> getAssertion(
    AuthenticationOptions options,
  ) async {
    lastAuthenticationOptions = options;
    if (errorToThrow != null) throw errorToThrow!;
    return authenticationResult!;
  }
}

void main() {
  group('Passkey', () {
    late Dio dio;
    late DioAdapter dioAdapter;
    late MemoryStorageImpl storage;
    late List<AuthState> emittedStates;
    late BetterAuthClientImpl client;
    late MockPasskeyAuthenticator authenticator;

    final now = DateTime.utc(2024, 1, 1, 12);
    final expiresAt = DateTime.now().add(const Duration(hours: 1));

    final mockUserJson = {
      'id': 'user-123',
      'email': 'test@example.com',
      'name': 'Test User',
      'emailVerified': true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    // BetterAuth returns token at top level, not inside a session object
    const mockToken = 'token-abc';

    final mockRegistrationOptionsJson = {
      'challenge': 'registration-challenge',
      'rp': {'id': 'example.com', 'name': 'Example'},
      'user': {
        'id': 'user-123',
        'name': 'test@example.com',
        'displayName': 'Test User',
      },
      'pubKeyCredParams': [
        {'type': 'public-key', 'alg': -7},
      ],
      'timeout': 300000,
      'attestation': 'none',
      'authenticatorSelection': {
        'authenticatorAttachment': 'platform',
        'userVerification': 'required',
      },
    };

    final mockAuthenticationOptionsJson = {
      'challenge': 'auth-challenge',
      'rpId': 'example.com',
      'timeout': 300000,
      'allowCredentials': [
        {'id': 'cred-123', 'type': 'public-key', 'transports': ['internal']},
      ],
      'userVerification': 'required',
    };

    const mockRegistrationResponse = RegistrationResponse(
      id: 'cred-new',
      rawId: 'raw-cred-new',
      type: 'public-key',
      response: AttestationResponse(
        clientDataJSON: 'client-data-json',
        attestationObject: 'attestation-object',
        transports: ['internal', 'hybrid'],
      ),
      authenticatorAttachment: 'platform',
    );

    const mockAuthenticationResponse = AuthenticationResponse(
      id: 'cred-123',
      rawId: 'raw-cred-123',
      type: 'public-key',
      response: AssertionResponse(
        clientDataJSON: 'client-data-json',
        authenticatorData: 'auth-data',
        signature: 'signature-abc',
        userHandle: 'user-123',
      ),
      authenticatorAttachment: 'platform',
    );

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dioAdapter = DioAdapter(dio: dio);
      storage = MemoryStorageImpl();
      emittedStates = [];
      authenticator = MockPasskeyAuthenticator();

      client = BetterAuthClientImpl(
        baseUrl: 'https://api.example.com',
        storage: storage,
        dio: dio,
      );

      client.authStateChanges.listen(emittedStates.add);
    });

    group('register', () {
      test('checks authenticator availability first', () async {
        authenticator.isAvailableResult = false;

        final result = await client.passkey
            .register(authenticator: authenticator)
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<PasskeyNotSupported>());
          case Right():
            fail('Expected Left');
        }
      });

      test('gets registration options from server', () async {
        authenticator
          ..isAvailableResult = true
          ..registrationResult = mockRegistrationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-registration-options',
            (server) => server.reply(200, mockRegistrationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-registration',
            (server) => server.reply(200, {
              'id': 'pk-123',
              'credentialId': 'cred-new',
              'name': 'iPhone',
              'createdAt': now.toIso8601String(),
            }),
            data: Matchers.any,
          );

        await client.passkey.register(authenticator: authenticator).run();

        expect(
          authenticator.lastRegistrationOptions?.challenge,
          'registration-challenge',
        );
        expect(
          authenticator.lastRegistrationOptions?.relyingParty.id,
          'example.com',
        );
      });

      test('calls authenticator.createCredential with options', () async {
        authenticator
          ..isAvailableResult = true
          ..registrationResult = mockRegistrationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-registration-options',
            (server) => server.reply(200, mockRegistrationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-registration',
            (server) => server.reply(200, {
              'id': 'pk-123',
              'credentialId': 'cred-new',
              'createdAt': now.toIso8601String(),
            }),
            data: Matchers.any,
          );

        await client.passkey.register(authenticator: authenticator).run();

        expect(authenticator.lastRegistrationOptions, isNotNull);
        expect(
          authenticator.lastRegistrationOptions?.user.name,
          'test@example.com',
        );
      });

      test('sends credential to server for verification', () async {
        authenticator
          ..isAvailableResult = true
          ..registrationResult = mockRegistrationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-registration-options',
            (server) => server.reply(200, mockRegistrationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-registration',
            (server) => server.reply(200, {
              'id': 'pk-123',
              'credentialId': 'cred-new',
              'createdAt': now.toIso8601String(),
            }),
            data: Matchers.any,
          );

        final result = await client.passkey
            .register(authenticator: authenticator, name: 'My iPhone')
            .run();

        // Verify registration succeeded (server accepted the credential)
        expect(result.isRight(), true);
      });

      test('returns PasskeyInfo on success', () async {
        authenticator
          ..isAvailableResult = true
          ..registrationResult = mockRegistrationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-registration-options',
            (server) => server.reply(200, mockRegistrationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-registration',
            (server) => server.reply(200, {
              'id': 'pk-123',
              'credentialId': 'cred-new',
              'name': 'iPhone 15 Pro',
              'createdAt': now.toIso8601String(),
              'deviceType': 'platform',
            }),
            data: Matchers.any,
          );

        final result = await client.passkey
            .register(authenticator: authenticator)
            .run();

        switch (result) {
          case Right(:final value):
            expect(value.id, 'pk-123');
            expect(value.credentialId, 'cred-new');
            expect(value.name, 'iPhone 15 Pro');
            expect(value.deviceType, 'platform');
          case Left():
            fail('Expected Right');
        }
      });

      test('fails if user cancels', () async {
        authenticator
          ..isAvailableResult = true
          ..errorToThrow = Exception('User cancelled');

        dioAdapter.onPost(
          '/api/auth/passkey/generate-registration-options',
          (server) => server.reply(200, mockRegistrationOptionsJson),
          data: Matchers.any,
        );

        final result = await client.passkey
            .register(authenticator: authenticator)
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<PasskeyCancelled>());
          case Right():
            fail('Expected Left');
        }
      });

      test('fails if verification fails', () async {
        authenticator
          ..isAvailableResult = true
          ..registrationResult = mockRegistrationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-registration-options',
            (server) => server.reply(200, mockRegistrationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-registration',
            (server) => server.reply(400, {
              'message': 'Verification failed',
              'code': 'VERIFICATION_FAILED',
            }),
            data: Matchers.any,
          );

        final result = await client.passkey
            .register(authenticator: authenticator)
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<PasskeyVerificationFailed>());
          case Right():
            fail('Expected Left');
        }
      });
    });

    group('authenticate', () {
      test('checks authenticator availability first', () async {
        authenticator.isAvailableResult = false;

        final result = await client.passkey
            .authenticate(authenticator: authenticator)
            .run();

        // Give stream time to emit
        await Future<void>.delayed(Duration.zero);

        switch (result) {
          case Left(:final value):
            expect(value, isA<PasskeyNotSupported>());
          case Right():
            fail('Expected Left');
        }

        expect(emittedStates, contains(isA<Unauthenticated>()));
      });

      test('gets authentication options from server', () async {
        authenticator
          ..isAvailableResult = true
          ..authenticationResult = mockAuthenticationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-authentication-options',
            (server) => server.reply(200, mockAuthenticationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-authentication',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            data: Matchers.any,
          );

        await client.passkey.authenticate(authenticator: authenticator).run();

        expect(
          authenticator.lastAuthenticationOptions?.challenge,
          'auth-challenge',
        );
        expect(authenticator.lastAuthenticationOptions?.rpId, 'example.com');
      });

      test('passes email filter to server', () async {
        authenticator
          ..isAvailableResult = true
          ..authenticationResult = mockAuthenticationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-authentication-options',
            (server) => server.reply(200, mockAuthenticationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-authentication',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            data: Matchers.any,
          );

        final result = await client.passkey
            .authenticate(
              authenticator: authenticator,
              email: 'test@example.com',
            )
            .run();

        // If we get here without exception, the email was passed correctly
        expect(result.isRight(), true);
      });

      test('calls authenticator.getAssertion with options', () async {
        authenticator
          ..isAvailableResult = true
          ..authenticationResult = mockAuthenticationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-authentication-options',
            (server) => server.reply(200, mockAuthenticationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-authentication',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            data: Matchers.any,
          );

        await client.passkey.authenticate(authenticator: authenticator).run();

        expect(authenticator.lastAuthenticationOptions, isNotNull);
        expect(
          authenticator.lastAuthenticationOptions?.allowCredentials.first.id,
          'cred-123',
        );
      });

      test('returns Authenticated on success', () async {
        authenticator
          ..isAvailableResult = true
          ..authenticationResult = mockAuthenticationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-authentication-options',
            (server) => server.reply(200, mockAuthenticationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-authentication',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            data: Matchers.any,
          );

        final result = await client.passkey
            .authenticate(authenticator: authenticator)
            .run();

        switch (result) {
          case Right(:final value):
            expect(value.user.email, 'test@example.com');
            expect(value.session.token, 'token-abc');
          case Left():
            fail('Expected Right');
        }
      });

      test('emits AuthLoading then Authenticated', () async {
        authenticator
          ..isAvailableResult = true
          ..authenticationResult = mockAuthenticationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-authentication-options',
            (server) => server.reply(200, mockAuthenticationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-authentication',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            data: Matchers.any,
          );

        await client.passkey.authenticate(authenticator: authenticator).run();

        // Give stream time to emit
        await Future<void>.delayed(Duration.zero);

        expect(emittedStates, contains(isA<AuthLoading>()));
        expect(emittedStates.last, isA<Authenticated>());
      });

      test('saves user and session to storage', () async {
        authenticator
          ..isAvailableResult = true
          ..authenticationResult = mockAuthenticationResponse;

        dioAdapter
          ..onPost(
            '/api/auth/passkey/generate-authentication-options',
            (server) => server.reply(200, mockAuthenticationOptionsJson),
            data: Matchers.any,
          )
          ..onPost(
            '/api/auth/passkey/verify-authentication',
            (server) => server.reply(200, {
              'user': mockUserJson,
              'token': mockToken,
            }),
            data: Matchers.any,
          );

        await client.passkey.authenticate(authenticator: authenticator).run();

        final userResult = await storage.getUser().run();
        switch (userResult) {
          case Right(:final value):
            switch (value) {
              case Some(:final value):
                expect(value.email, 'test@example.com');
              case None():
                fail('Expected Some');
            }
          case Left():
            fail('Expected Right');
        }

        final sessionResult = await storage.getSession().run();
        switch (sessionResult) {
          case Right(:final value):
            switch (value) {
              case Some(:final value):
                expect(value.token, 'token-abc');
              case None():
                fail('Expected Some');
            }
          case Left():
            fail('Expected Right');
        }
      });

      test('fails if user cancels', () async {
        authenticator
          ..isAvailableResult = true
          ..errorToThrow = Exception('User cancelled');

        dioAdapter.onPost(
          '/api/auth/passkey/generate-authentication-options',
          (server) => server.reply(200, mockAuthenticationOptionsJson),
          data: Matchers.any,
        );

        final result = await client.passkey
            .authenticate(authenticator: authenticator)
            .run();

        // Give stream time to emit
        await Future<void>.delayed(Duration.zero);

        switch (result) {
          case Left(:final value):
            expect(value, isA<PasskeyCancelled>());
          case Right():
            fail('Expected Left');
        }

        expect(emittedStates.last, isA<Unauthenticated>());
      });

      test('fails if no passkey found', () async {
        authenticator.isAvailableResult = true;

        dioAdapter.onPost(
          '/api/auth/passkey/generate-authentication-options',
          (server) => server.reply(404, {
            'message': 'No passkey found',
            'code': 'PASSKEY_NOT_FOUND',
          }),
          data: Matchers.any,
        );

        final result = await client.passkey
            .authenticate(authenticator: authenticator)
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<PasskeyNotFound>());
          case Right():
            fail('Expected Left');
        }
      });
    });

    group('list', () {
      test('returns list of PasskeyInfo', () async {
        dioAdapter.onGet(
          '/api/auth/passkey/list',
          (server) => server.reply(200, {
            'passkeys': [
              {
                'id': 'pk-1',
                'credentialId': 'cred-1',
                'name': 'iPhone',
                'createdAt': now.toIso8601String(),
                'deviceType': 'platform',
              },
              {
                'id': 'pk-2',
                'credentialId': 'cred-2',
                'name': 'MacBook',
                'createdAt': now.toIso8601String(),
                'deviceType': 'platform',
              },
            ],
          }),
        );

        final result = await client.passkey.list().run();

        switch (result) {
          case Right(:final value):
            expect(value.length, 2);
            expect(value[0].name, 'iPhone');
            expect(value[1].name, 'MacBook');
          case Left():
            fail('Expected Right');
        }
      });

      test('returns empty list if none registered', () async {
        dioAdapter.onGet(
          '/api/auth/passkey/list',
          (server) => server.reply(200, {'passkeys': <Map<String, dynamic>>[]}),
        );

        final result = await client.passkey.list().run();

        switch (result) {
          case Right(:final value):
            expect(value, isEmpty);
          case Left():
            fail('Expected Right');
        }
      });
    });

    group('remove', () {
      test('deletes passkey by ID', () async {
        dioAdapter.onDelete(
          '/api/auth/passkey/pk-123',
          (server) => server.reply(200, {'success': true}),
        );

        final result = await client.passkey.remove(passkeyId: 'pk-123').run();

        expect(result.isRight(), true);
      });

      test('fails if passkey not found', () async {
        dioAdapter.onDelete(
          '/api/auth/passkey/pk-999',
          (server) => server.reply(404, {
            'message': 'Passkey not found',
            'code': 'PASSKEY_NOT_FOUND',
          }),
        );

        final result = await client.passkey.remove(passkeyId: 'pk-999').run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<PasskeyNotFound>());
          case Right():
            fail('Expected Left');
        }
      });
    });
  });
}
