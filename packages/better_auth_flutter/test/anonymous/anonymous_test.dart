import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/auth_test_harness.dart';

class MockOAuthProvider extends Mock implements OAuthProvider {}

void main() {
  final harness = AuthTestHarness();
  late Anonymous anonymous;

  setUp(() {
    harness.setUp();
    anonymous = Anonymous(harness.pluginContext);
  });

  tearDown(harness.tearDown);

  group('Anonymous.signIn', () {
    test('creates anonymous user and returns Authenticated', () async {
      harness.onPost(
        '/api/auth/anonymous/sign-in',
        AuthFixtures.anonymousAuthResponse(),
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
      harness.onPost(
        '/api/auth/anonymous/sign-in',
        AuthFixtures.anonymousAuthResponse(),
      );

      final states = await harness.collectStates(
        () => anonymous.signIn().run(),
      );

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('persists user and session to storage', () async {
      harness.onPost(
        '/api/auth/anonymous/sign-in',
        AuthFixtures.anonymousAuthResponse(),
      );

      await anonymous.signIn().run();

      final userResult = await harness.storage.getUser().run();
      final sessionResult = await harness.storage.getSession().run();

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
      harness.onNetworkError('/api/auth/anonymous/sign-in');

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
      harness.onPost(
        '/api/auth/anonymous/sign-in',
        AuthFixtures.error(message: 'Server error'),
        statusCode: 500,
      );

      final states = await harness.collectStates(
        () => anonymous.signIn().run(),
      );

      expect(states, contains(isA<Unauthenticated>()));
    });
  });

  group('Anonymous.linkEmail', () {
    final mockLinkedAuthResponse = AuthFixtures.authResponse(
      userId: 'anon-user-123',
      email: 'upgraded@example.com',
      name: 'New User',
      emailVerified: false,
      sessionId: 'session-789',
      token: 'linked-token-xyz',
      expiresIn: const Duration(days: 30),
    );

    test('links email and returns Authenticated', () async {
      harness.onPost(
        '/api/auth/anonymous/link',
        mockLinkedAuthResponse,
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
      harness.onPost(
        '/api/auth/anonymous/link',
        mockLinkedAuthResponse,
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
      harness.onPost(
        '/api/auth/anonymous/link',
        mockLinkedAuthResponse,
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
      harness.onPost(
        '/api/auth/anonymous/link',
        mockLinkedAuthResponse,
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
        },
      );

      final states = await harness.collectStates(
        () => anonymous
            .linkEmail(
              email: 'upgraded@example.com',
              password: 'password',
            )
            .run(),
      );

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('returns NotAnonymous when user is not anonymous', () async {
      harness.onPost(
        '/api/auth/anonymous/link',
        AuthFixtures.error(
          message: 'Current user is not anonymous',
          code: 'NOT_ANONYMOUS',
        ),
        statusCode: 400,
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
      harness.onPost(
        '/api/auth/anonymous/link',
        AuthFixtures.error(
          message: 'Email already in use',
          code: 'EMAIL_ALREADY_EXISTS',
        ),
        statusCode: 409,
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
      harness.onPost(
        '/api/auth/anonymous/link',
        AuthFixtures.error(
          message: 'Account already linked',
          code: 'ACCOUNT_ALREADY_LINKED',
        ),
        statusCode: 400,
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
      harness.onPost(
        '/api/auth/anonymous/link',
        AuthFixtures.error(
          message: 'Not anonymous',
          code: 'NOT_ANONYMOUS',
        ),
        statusCode: 400,
        data: {
          'email': 'upgraded@example.com',
          'password': 'password',
        },
      );

      final states = await harness.collectStates(
        () => anonymous
            .linkEmail(
              email: 'upgraded@example.com',
              password: 'password',
            )
            .run(),
      );

      expect(states, contains(isA<Unauthenticated>()));
    });
  });

  group('Anonymous.linkSocial', () {
    late MockOAuthProvider mockProvider;

    final mockLinkedAuthResponse = AuthFixtures.authResponse(
      userId: 'anon-user-123',
      email: 'upgraded@example.com',
      name: 'New User',
      emailVerified: false,
      sessionId: 'session-789',
      token: 'linked-token-xyz',
      expiresIn: const Duration(days: 30),
    );

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

      harness.onPost(
        '/api/auth/anonymous/link',
        mockLinkedAuthResponse,
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

      harness.onPost(
        '/api/auth/anonymous/link',
        mockLinkedAuthResponse,
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

      harness.onPost(
        '/api/auth/anonymous/link',
        AuthFixtures.error(
          message: 'Current user is not anonymous',
          code: 'NOT_ANONYMOUS',
        ),
        statusCode: 400,
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

      harness.onPost(
        '/api/auth/anonymous/link',
        AuthFixtures.error(
          message: 'Account already linked',
          code: 'ACCOUNT_ALREADY_LINKED',
        ),
        statusCode: 400,
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

      harness.onPost(
        '/api/auth/anonymous/link',
        mockLinkedAuthResponse,
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      final states = await harness.collectStates(
        () => anonymous.linkSocial(provider: mockProvider).run(),
      );

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

      harness.onPost(
        '/api/auth/anonymous/link',
        AuthFixtures.error(
          message: 'Not anonymous',
          code: 'NOT_ANONYMOUS',
        ),
        statusCode: 400,
        data: {
          'providerId': 'google',
          'idToken': 'google-id-token',
          'accessToken': 'google-access-token',
        },
      );

      final states = await harness.collectStates(
        () => anonymous.linkSocial(provider: mockProvider).run(),
      );

      expect(states, contains(isA<Unauthenticated>()));
    });
  });
}
