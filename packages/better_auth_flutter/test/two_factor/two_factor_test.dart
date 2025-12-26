import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_harness.dart';

void main() {
  final harness = AuthTestHarness();
  late TwoFactor twoFactor;

  setUp(() {
    harness.setUp();
    twoFactor = TwoFactor(harness.pluginContext);
  });

  tearDown(harness.tearDown);

  group('TwoFactor.enable', () {
    test('returns TwoFactorSetup on success', () async {
      harness.onPost(
        '/api/auth/two-factor/enable',
        AuthFixtures.twoFactorSetup(),
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
      harness.onPost(
        '/api/auth/two-factor/enable',
        AuthFixtures.twoFactorSetup(
          totpUri: 'otpauth://totp/CustomApp:user@example.com?secret=ABC123',
        ),
        data: {'password': 'password123', 'issuer': 'CustomApp'},
      );

      final result = await twoFactor
          .enable(password: 'password123', issuer: 'CustomApp')
          .run();

      expect(result.isRight(), true);
    });

    test('returns error when already enabled', () async {
      harness.onPost(
        '/api/auth/two-factor/enable',
        AuthFixtures.error(
          message: 'Two-factor already enabled',
          code: 'TWO_FACTOR_ALREADY_ENABLED',
        ),
        statusCode: 400,
        data: {'password': 'password123'},
      );

      final result = await twoFactor.enable(password: 'password123').run();

      expect(result.isLeft(), true);
    });

    test('returns error on invalid password', () async {
      harness.onPost(
        '/api/auth/two-factor/enable',
        AuthFixtures.error(message: 'Invalid password'),
        statusCode: 401,
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
      harness.onPost(
        '/api/auth/two-factor/get-totp-uri',
        {'totpURI': 'otpauth://totp/MyApp:user@example.com?secret=ABC123'},
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
      harness.onPost(
        '/api/auth/two-factor/disable',
        {'success': true},
        data: {'password': 'password123'},
      );

      final result = await twoFactor.disable(password: 'password123').run();

      expect(result.isRight(), true);
    });

    test('returns error on invalid password', () async {
      harness.onPost(
        '/api/auth/two-factor/disable',
        AuthFixtures.error(message: 'Invalid password'),
        statusCode: 401,
        data: {'password': 'wrongpassword'},
      );

      final result = await twoFactor.disable(password: 'wrongpassword').run();

      expect(result.isLeft(), true);
    });
  });

  group('TwoFactor.verifyTotp', () {
    test('returns Authenticated on valid code', () async {
      harness.onPost(
        '/api/auth/two-factor/verify-totp',
        AuthFixtures.authResponse(),
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
      harness.onPost(
        '/api/auth/two-factor/verify-totp',
        AuthFixtures.authResponse(),
        data: {'code': '123456', 'trustDevice': true},
      );

      final result = await twoFactor
          .verifyTotp(code: '123456', trustDevice: true)
          .run();

      expect(result.isRight(), true);
    });

    test('persists user and session on success', () async {
      harness.onPost(
        '/api/auth/two-factor/verify-totp',
        AuthFixtures.authResponse(),
        data: {'code': '123456'},
      );

      await twoFactor.verifyTotp(code: '123456').run();

      final userResult = await harness.storage.getUser().run();
      final sessionResult = await harness.storage.getSession().run();

      expect(userResult.isRight(), true);
      expect(sessionResult.isRight(), true);
    });

    test('emits AuthLoading then Authenticated', () async {
      harness.onPost(
        '/api/auth/two-factor/verify-totp',
        AuthFixtures.authResponse(),
        data: {'code': '123456'},
      );

      final states = await harness.collectStates(
        () => twoFactor.verifyTotp(code: '123456').run(),
      );

      expect(states, contains(isA<AuthLoading>()));
      expect(states, contains(isA<Authenticated>()));
    });

    test('returns error on invalid code', () async {
      harness.onPost(
        '/api/auth/two-factor/verify-totp',
        AuthFixtures.error(message: 'Invalid code', code: 'INVALID_CODE'),
        statusCode: 400,
        data: {'code': '000000'},
      );

      final result = await twoFactor.verifyTotp(code: '000000').run();

      expect(result.isLeft(), true);
    });
  });

  group('TwoFactor.verifyBackupCode', () {
    test('returns Authenticated on valid backup code', () async {
      harness.onPost(
        '/api/auth/two-factor/verify-backup-code',
        AuthFixtures.authResponse(),
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
      harness.onPost(
        '/api/auth/two-factor/verify-backup-code',
        AuthFixtures.authResponse(),
        data: {'code': 'backup-code-1', 'trustDevice': true},
      );

      final result = await twoFactor
          .verifyBackupCode(code: 'backup-code-1', trustDevice: true)
          .run();

      expect(result.isRight(), true);
    });

    test('returns error on invalid backup code', () async {
      harness.onPost(
        '/api/auth/two-factor/verify-backup-code',
        AuthFixtures.error(message: 'Invalid backup code', code: 'INVALID_CODE'),
        statusCode: 400,
        data: {'code': 'invalid-code'},
      );

      final result =
          await twoFactor.verifyBackupCode(code: 'invalid-code').run();

      expect(result.isLeft(), true);
    });
  });

  group('TwoFactor.generateBackupCodes', () {
    test('returns new backup codes on success', () async {
      harness.onPost(
        '/api/auth/two-factor/generate-backup-codes',
        {'backupCodes': ['new-code-1', 'new-code-2', 'new-code-3']},
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
      harness.onPost(
        '/api/auth/two-factor/generate-backup-codes',
        AuthFixtures.error(message: 'Invalid password'),
        statusCode: 401,
        data: {'password': 'wrongpassword'},
      );

      final result =
          await twoFactor.generateBackupCodes(password: 'wrongpassword').run();

      expect(result.isLeft(), true);
    });
  });
}
