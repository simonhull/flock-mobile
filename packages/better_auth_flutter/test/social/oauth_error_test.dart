import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthError', () {
    test('OAuthCancelled has expected message', () {
      const error = OAuthCancelled();

      expect(error.message, 'Sign in cancelled');
      expect(error, isA<AuthError>());
    });

    test('OAuthConfigurationError includes details', () {
      const error = OAuthConfigurationError(details: 'Missing client ID');

      expect(error.message, 'OAuth configuration error: Missing client ID');
      expect(error.details, 'Missing client ID');
    });

    test('OAuthProviderError includes provider and details', () {
      const error = OAuthProviderError(
        provider: 'Google',
        details: 'Network timeout',
      );

      expect(error.message, 'Google error: Network timeout');
      expect(error.provider, 'Google');
      expect(error.details, 'Network timeout');
    });

    test('OAuthTokenRejected with reason', () {
      const error = OAuthTokenRejected(reason: 'Token expired');

      expect(error.message, 'Token expired');
      expect(error.reason, 'Token expired');
    });

    test('OAuthTokenRejected without reason uses default', () {
      const error = OAuthTokenRejected();

      expect(error.message, 'Token rejected by server');
      expect(error.reason, isNull);
    });

    test('OAuth errors are AuthError subtypes', () {
      const AuthError error = OAuthCancelled();

      // Pattern match on OAuth errors within AuthError
      final result = switch (error) {
        OAuthCancelled() => 'cancelled',
        OAuthConfigurationError() => 'config',
        OAuthProviderError() => 'provider',
        OAuthTokenRejected() => 'rejected',
        _ => 'other',
      };

      expect(result, 'cancelled');
    });
  });
}
