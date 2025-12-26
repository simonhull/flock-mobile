import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TwoFactorSetup', () {
    test('creates from constructor', () {
      const setup = TwoFactorSetup(
        totpUri: 'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
        secret: 'ABC123',
        backupCodes: ['code1', 'code2', 'code3'],
      );

      expect(
        setup.totpUri,
        'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
      );
      expect(setup.secret, 'ABC123');
      expect(setup.backupCodes, ['code1', 'code2', 'code3']);
    });

    test('creates from JSON', () {
      final json = {
        'totpURI': 'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
        'secret': 'ABC123',
        'backupCodes': ['code1', 'code2', 'code3'],
      };

      final setup = TwoFactorSetup.fromJson(json);

      expect(
        setup.totpUri,
        'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
      );
      expect(setup.secret, 'ABC123');
      expect(setup.backupCodes, ['code1', 'code2', 'code3']);
    });

    test('handles empty backup codes', () {
      final json = {
        'totpURI': 'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
        'secret': 'ABC123',
        'backupCodes': <String>[],
      };

      final setup = TwoFactorSetup.fromJson(json);

      expect(setup.backupCodes, isEmpty);
    });

    test('equality based on all fields', () {
      const setup1 = TwoFactorSetup(
        totpUri: 'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
        secret: 'ABC123',
        backupCodes: ['code1', 'code2'],
      );

      const setup2 = TwoFactorSetup(
        totpUri: 'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
        secret: 'ABC123',
        backupCodes: ['code1', 'code2'],
      );

      const setup3 = TwoFactorSetup(
        totpUri: 'otpauth://totp/MyApp:user@example.com?secret=XYZ789&issuer=MyApp',
        secret: 'XYZ789',
        backupCodes: ['code1', 'code2'],
      );

      expect(setup1, equals(setup2));
      expect(setup1, isNot(equals(setup3)));
    });

    test('toString includes relevant info', () {
      const setup = TwoFactorSetup(
        totpUri: 'otpauth://totp/MyApp:user@example.com?secret=ABC123&issuer=MyApp',
        secret: 'ABC123',
        backupCodes: ['code1', 'code2', 'code3'],
      );

      final str = setup.toString();

      expect(str, contains('TwoFactorSetup'));
      expect(str, contains('3 backup codes'));
    });
  });
}
