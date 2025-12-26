import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Passkey errors', () {
    test('PasskeyNotSupported has correct message and code', () {
      const error = PasskeyNotSupported();

      expect(error.message, 'Passkeys not supported on this device');
      expect(error.code, 'PASSKEY_NOT_SUPPORTED');
      expect(error, isA<AuthError>());
    });

    test('PasskeyCancelled has correct message and code', () {
      const error = PasskeyCancelled();

      expect(error.message, 'Passkey operation cancelled');
      expect(error.code, 'PASSKEY_CANCELLED');
      expect(error, isA<AuthError>());
    });

    test('PasskeyNotFound has correct message and code', () {
      const error = PasskeyNotFound();

      expect(error.message, 'No passkey found for this account');
      expect(error.code, 'PASSKEY_NOT_FOUND');
      expect(error, isA<AuthError>());
    });

    test('PasskeyVerificationFailed has correct message and code', () {
      const error = PasskeyVerificationFailed();

      expect(error.message, 'Passkey verification failed');
      expect(error.code, 'PASSKEY_VERIFICATION_FAILED');
      expect(error, isA<AuthError>());
    });
  });
}
