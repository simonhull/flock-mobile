import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('BetterAuthClientImpl', () {
    late MockDio mockDio;
    late MemoryStorageImpl storage;
    late BetterAuthClientImpl client;

    final now = DateTime.utc(2024, 1, 1, 12);
    final expiresAt = DateTime.now().add(const Duration(hours: 1));

    final mockUserJson = {
      'id': '123',
      'email': 'test@example.com',
      'name': 'Test User',
      'emailVerified': true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final mockSessionJson = {
      'id': 'session-123',
      'userId': '123',
      'token': 'token-abc',
      'expiresAt': expiresAt.toIso8601String(),
    };

    setUp(() {
      mockDio = MockDio();
      storage = MemoryStorageImpl();

      // Mock BaseOptions
      when(() => mockDio.options).thenReturn(
        BaseOptions(baseUrl: 'https://test.com'),
      );

      // Mock interceptors
      when(() => mockDio.interceptors).thenReturn(Interceptors());

      client = BetterAuthClientImpl(
        baseUrl: 'https://test.com',
        storage: storage,
        dio: mockDio,
      );
    });

    group('currentState', () {
      test('starts with AuthInitial', () {
        expect(client.currentState, isA<AuthInitial>());
      });

      test('currentUser is null when not authenticated', () {
        expect(client.currentUser, isNull);
      });
    });

    group('signUp', () {
      test('returns Authenticated on success', () async {
        when(
          () => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'user': mockUserJson, 'session': mockSessionJson},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .signUp(
              email: 'test@example.com',
              password: 'password123',
              name: 'Test User',
            )
            .run();

        switch (result) {
          case Right(:final value):
            expect(value.user.email, 'test@example.com');
            expect(value.session.token, 'token-abc');
          case Left():
            fail('Expected Right');
        }

        expect(client.currentState, isA<Authenticated>());
        expect(client.currentUser?.email, 'test@example.com');
      });

      test('returns UserAlreadyExists on 409', () async {
        when(
          () => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'message': 'User already exists'},
            statusCode: 409,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .signUp(
              email: 'test@example.com',
              password: 'password123',
            )
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<UserAlreadyExists>());
          case Right():
            fail('Expected Left');
        }

        expect(client.currentState, isA<Unauthenticated>());
      });
    });

    group('signIn', () {
      test('returns Authenticated on success', () async {
        when(
          () => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'user': mockUserJson, 'session': mockSessionJson},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .signIn(
              email: 'test@example.com',
              password: 'password123',
            )
            .run();

        switch (result) {
          case Right(:final value):
            expect(value.user.email, 'test@example.com');
          case Left():
            fail('Expected Right');
        }
      });

      test('returns InvalidCredentials on 401', () async {
        when(
          () => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'message': 'Invalid credentials'},
            statusCode: 401,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .signIn(
              email: 'test@example.com',
              password: 'wrong',
            )
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<InvalidCredentials>());
          case Right():
            fail('Expected Left');
        }
      });

      test('returns EmailNotVerified on 403 with code', () async {
        when(
          () => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'message': 'Email not verified',
              'code': 'EMAIL_NOT_VERIFIED',
            },
            statusCode: 403,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .signIn(
              email: 'test@example.com',
              password: 'password123',
            )
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<EmailNotVerified>());
          case Right():
            fail('Expected Left');
        }
      });

      test('returns TwoFactorRequired on twoFactorRedirect', () async {
        when(
          () => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'twoFactorRedirect': true},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .signIn(
              email: 'test@example.com',
              password: 'password123',
            )
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<TwoFactorRequired>());
          case Right():
            fail('Expected Left with TwoFactorRequired');
        }

        // Should NOT emit Unauthenticated - partial session in cookies
        expect(client.currentState, isNot(isA<Authenticated>()));
      });
    });

    group('signOut', () {
      test('clears auth state', () async {
        // First sign in
        when(
          () => mockDio.post<dynamic>(
            '/api/auth/sign-in/email',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'user': mockUserJson, 'session': mockSessionJson},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        await client
            .signIn(email: 'test@example.com', password: 'password')
            .run();

        expect(client.currentState, isA<Authenticated>());

        // Then sign out
        when(
          () => mockDio.post<dynamic>('/api/auth/sign-out'),
        ).thenAnswer(
          (_) async => Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client.signOut().run();

        expect(result.isRight(), true);
        expect(client.currentState, isA<Unauthenticated>());
        expect(client.currentUser, isNull);
      });
    });

    group('initialize', () {
      test('restores authenticated state from storage', () async {
        // Pre-populate storage
        await storage
            .saveUser(
              User(
                id: '123',
                email: 'test@example.com',
                emailVerified: true,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .run();
        await storage
            .saveSession(
              Session(
                id: 'session-123',
                userId: '123',
                token: 'token-abc',
                expiresAt: expiresAt,
              ),
            )
            .run();

        final result = await client.initialize().run();

        expect(result.isRight(), true);
        expect(client.currentState, isA<Authenticated>());
        expect(client.currentUser?.email, 'test@example.com');
      });

      test('sets unauthenticated when storage is empty', () async {
        final result = await client.initialize().run();

        expect(result.isRight(), true);
        expect(client.currentState, isA<Unauthenticated>());
      });

      test('sets unauthenticated when session is expired', () async {
        await storage
            .saveUser(
              User(
                id: '123',
                email: 'test@example.com',
                emailVerified: true,
                createdAt: now,
                updatedAt: now,
              ),
            )
            .run();
        await storage
            .saveSession(
              Session(
                id: 'session-123',
                userId: '123',
                token: 'token-abc',
                expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
              ),
            )
            .run();

        final result = await client.initialize().run();

        expect(result.isRight(), true);
        expect(client.currentState, isA<Unauthenticated>());
      });
    });

    group('authStateChanges', () {
      test('emits state changes', () async {
        when(
          () => mockDio.post<dynamic>(
            any(),
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'user': mockUserJson, 'session': mockSessionJson},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final states = <AuthState>[];
        final subscription = client.authStateChanges.listen(states.add);

        await client
            .signIn(email: 'test@example.com', password: 'password')
            .run();

        // Give stream time to emit
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        // Should have: Initial -> Loading -> Authenticated
        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.last, isA<Authenticated>());
      });
    });

    group('forgotPassword', () {
      test('always succeeds to not reveal email existence', () async {
        when(
          () => mockDio.post<dynamic>(
            '/api/auth/forget-password',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .forgotPassword(email: 'nonexistent@example.com')
            .run();

        expect(result.isRight(), true);
      });
    });

    group('resetPassword', () {
      test('returns success on valid token', () async {
        when(
          () => mockDio.post<dynamic>(
            '/api/auth/reset-password',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'success': true},
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .resetPassword(token: 'valid-token', newPassword: 'newpass123')
            .run();

        expect(result.isRight(), true);
      });

      test('returns InvalidToken on 400 with code', () async {
        when(
          () => mockDio.post<dynamic>(
            '/api/auth/reset-password',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'message': 'Invalid token', 'code': 'INVALID_TOKEN'},
            statusCode: 400,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await client
            .resetPassword(token: 'invalid-token', newPassword: 'newpass123')
            .run();

        switch (result) {
          case Left(:final value):
            expect(value, isA<InvalidToken>());
          case Right():
            fail('Expected Left');
        }
      });
    });
  });
}
