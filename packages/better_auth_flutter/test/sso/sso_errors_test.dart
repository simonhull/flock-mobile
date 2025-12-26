import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SSO errors', () {
    test('SSOProviderNotFound has correct message and code', () {
      const error = SSOProviderNotFound();
      expect(error.message, 'No SSO provider configured for this domain');
      expect(error.code, 'SSO_PROVIDER_NOT_FOUND');
    });

    test('SSOProviderDisabled has correct message and code', () {
      const error = SSOProviderDisabled();
      expect(error.message, 'SSO provider is disabled');
      expect(error.code, 'SSO_PROVIDER_DISABLED');
    });

    test('SSOCallbackError accepts custom message', () {
      const error = SSOCallbackError(message: 'Invalid authorization code');
      expect(error.message, 'Invalid authorization code');
      expect(error.code, 'SSO_CALLBACK_ERROR');
    });

    test('SSOStateMismatch has correct message and code', () {
      const error = SSOStateMismatch();
      expect(error.message, 'SSO state mismatch - possible CSRF attack');
      expect(error.code, 'SSO_STATE_MISMATCH');
    });

    test('SSOCancelled has correct message and code', () {
      const error = SSOCancelled();
      expect(error.message, 'SSO sign-in cancelled');
      expect(error.code, 'SSO_CANCELLED');
    });

    test('all SSO errors extend AuthError', () {
      const errors = <AuthError>[
        SSOProviderNotFound(),
        SSOProviderDisabled(),
        SSOCallbackError(message: 'test'),
        SSOStateMismatch(),
        SSOCancelled(),
      ];

      for (final error in errors) {
        expect(error, isA<AuthError>());
      }
    });
  });
}
