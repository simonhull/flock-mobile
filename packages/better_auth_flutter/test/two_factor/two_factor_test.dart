import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late BetterAuthClientImpl client;
  late MemoryStorageImpl storage;
  late TwoFactor twoFactor;

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
    twoFactor = TwoFactor(client);
  });

  tearDown(() async {
    await client.dispose();
  });

  group('TwoFactor.enable', () {
    test('returns TwoFactorSetup on success', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/enable',
        (server) => server.reply(200, {
          'totpURI': 'otpauth://totp/MyApp:user@example.com?secret=ABC123',
          'secret': 'ABC123',
          'backupCodes': ['code1', 'code2', 'code3'],
        }),
        data: {'password': 'password123'},
      );

      final result = await twoFactor.enable(password: 'password123').run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (setup) {
          expect(setup.totpUri, contains('otpauth://totp/'));
          expect(setup.secret, 'ABC123');
          expect(setup.backupCodes, hasLength(3));
        },
      );
    });

    test('sends issuer when provided', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/enable',
        (server) => server.reply(200, {
          'totpURI': 'otpauth://totp/CustomApp:user@example.com?secret=ABC123',
          'secret': 'ABC123',
          'backupCodes': ['code1'],
        }),
        data: {'password': 'password123', 'issuer': 'CustomApp'},
      );

      final result = await twoFactor
          .enable(password: 'password123', issuer: 'CustomApp')
          .run();

      expect(result.isRight(), true);
    });

    test('returns error when already enabled', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/enable',
        (server) => server.reply(400, {
          'message': 'Two-factor already enabled',
          'code': 'TWO_FACTOR_ALREADY_ENABLED',
        }),
        data: {'password': 'password123'},
      );

      final result = await twoFactor.enable(password: 'password123').run();

      expect(result.isLeft(), true);
    });

    test('returns error on invalid password', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/enable',
        (server) => server.reply(401, {'message': 'Invalid password'}),
        data: {'password': 'wrongpassword'},
      );

      final result = await twoFactor.enable(password: 'wrongpassword').run();

      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, isA<InvalidCredentials>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('TwoFactor.getTotpUri', () {
    test('returns TOTP URI on success', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/get-totp-uri',
        (server) => server.reply(200, {
          'totpURI': 'otpauth://totp/MyApp:user@example.com?secret=ABC123',
        }),
        data: {'password': 'password123'},
      );

      final result = await twoFactor.getTotpUri(password: 'password123').run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (uri) => expect(uri, contains('otpauth://totp/')),
      );
    });
  });

  group('TwoFactor.disable', () {
    test('succeeds with valid password', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/disable',
        (server) => server.reply(200, {'success': true}),
        data: {'password': 'password123'},
      );

      final result = await twoFactor.disable(password: 'password123').run();

      expect(result.isRight(), true);
    });

    test('returns error on invalid password', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/disable',
        (server) => server.reply(401, {'message': 'Invalid password'}),
        data: {'password': 'wrongpassword'},
      );

      final result = await twoFactor.disable(password: 'wrongpassword').run();

      expect(result.isLeft(), true);
    });
  });

  group('TwoFactor.verifyTotp', () {
    test('returns Authenticated on valid code', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-totp',
        (server) => server.reply(200, mockAuthResponse),
        data: {'code': '123456'},
      );

      final result = await twoFactor.verifyTotp(code: '123456').run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (state) {
          expect(state, isA<Authenticated>());
          expect(state.user.email, 'test@example.com');
        },
      );
    });

    test('sends trustDevice when true', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-totp',
        (server) => server.reply(200, mockAuthResponse),
        data: {'code': '123456', 'trustDevice': true},
      );

      final result = await twoFactor
          .verifyTotp(code: '123456', trustDevice: true)
          .run();

      expect(result.isRight(), true);
    });

    test('persists user and session on success', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-totp',
        (server) => server.reply(200, mockAuthResponse),
        data: {'code': '123456'},
      );

      await twoFactor.verifyTotp(code: '123456').run();

      final userResult = await storage.getUser().run();
      final sessionResult = await storage.getSession().run();

      expect(userResult.isRight(), true);
      expect(sessionResult.isRight(), true);
    });

    test('emits AuthLoading then Authenticated', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-totp',
        (server) => server.reply(200, mockAuthResponse),
        data: {'code': '123456'},
      );

      final states = <AuthState>[];
      client.authStateChanges.listen(states.add);

      await twoFactor.verifyTotp(code: '123456').run();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('returns error on invalid code', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-totp',
        (server) => server.reply(400, {
          'message': 'Invalid code',
          'code': 'INVALID_CODE',
        }),
        data: {'code': '000000'},
      );

      final result = await twoFactor.verifyTotp(code: '000000').run();

      expect(result.isLeft(), true);
    });
  });

  group('TwoFactor.verifyBackupCode', () {
    test('returns Authenticated on valid backup code', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-backup-code',
        (server) => server.reply(200, mockAuthResponse),
        data: {'code': 'backup-code-1'},
      );

      final result =
          await twoFactor.verifyBackupCode(code: 'backup-code-1').run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (state) => expect(state, isA<Authenticated>()),
      );
    });

    test('sends trustDevice when true', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-backup-code',
        (server) => server.reply(200, mockAuthResponse),
        data: {'code': 'backup-code-1', 'trustDevice': true},
      );

      final result = await twoFactor
          .verifyBackupCode(code: 'backup-code-1', trustDevice: true)
          .run();

      expect(result.isRight(), true);
    });

    test('returns error on invalid backup code', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/verify-backup-code',
        (server) => server.reply(400, {
          'message': 'Invalid backup code',
          'code': 'INVALID_CODE',
        }),
        data: {'code': 'invalid-code'},
      );

      final result =
          await twoFactor.verifyBackupCode(code: 'invalid-code').run();

      expect(result.isLeft(), true);
    });
  });

  group('TwoFactor.generateBackupCodes', () {
    test('returns new backup codes on success', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/generate-backup-codes',
        (server) => server.reply(200, {
          'backupCodes': ['new-code-1', 'new-code-2', 'new-code-3'],
        }),
        data: {'password': 'password123'},
      );

      final result =
          await twoFactor.generateBackupCodes(password: 'password123').run();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (codes) {
          expect(codes, hasLength(3));
          expect(codes.first, 'new-code-1');
        },
      );
    });

    test('returns error on invalid password', () async {
      dioAdapter.onPost(
        '/api/auth/two-factor/generate-backup-codes',
        (server) => server.reply(401, {'message': 'Invalid password'}),
        data: {'password': 'wrongpassword'},
      );

      final result =
          await twoFactor.generateBackupCodes(password: 'wrongpassword').run();

      expect(result.isLeft(), true);
    });
  });
}
