import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthError', () {
    test('NetworkError has default message', () {
      const error = NetworkError();
      expect(error.message, 'No internet connection');
      expect(error.code, isNull);
    });

    test('NetworkError accepts custom message', () {
      const error = NetworkError(message: 'Connection timeout');
      expect(error.message, 'Connection timeout');
    });

    test('InvalidCredentials has fixed message', () {
      const error = InvalidCredentials();
      expect(error.message, 'Invalid email or password');
    });

    test('EmailNotVerified has fixed message', () {
      const error = EmailNotVerified();
      expect(error.message, 'Please verify your email');
    });

    test('UserAlreadyExists has fixed message', () {
      const error = UserAlreadyExists();
      expect(error.message, 'An account with this email already exists');
    });

    test('TokenExpired has fixed message', () {
      const error = TokenExpired();
      expect(error.message, 'Session expired, please sign in again');
    });

    test('InvalidToken has fixed message', () {
      const error = InvalidToken();
      expect(error.message, 'Invalid or expired token');
    });

    test('NotAuthenticated has fixed message', () {
      const error = NotAuthenticated();
      expect(error.message, 'Please sign in to continue');
    });

    test('UnknownError accepts custom message and code', () {
      const error = UnknownError(message: 'Something went wrong', code: 'ERR');
      expect(error.message, 'Something went wrong');
      expect(error.code, 'ERR');
    });

    test('exhaustive switch on AuthError', () {
      String getErrorType(AuthError error) => switch (error) {
            NetworkError() => 'network',
            InvalidCredentials() => 'credentials',
            EmailNotVerified() => 'unverified',
            UserAlreadyExists() => 'exists',
            TokenExpired() => 'expired',
            NotAuthenticated() => 'not_authenticated',
            InvalidToken() => 'invalid_token',
            UnknownError() => 'unknown',
            // OAuth errors
            OAuthCancelled() => 'oauth_cancelled',
            OAuthConfigurationError() => 'oauth_config',
            OAuthProviderError() => 'oauth_provider',
            OAuthTokenRejected() => 'oauth_rejected',
          };

      expect(getErrorType(const NetworkError()), 'network');
      expect(getErrorType(const InvalidCredentials()), 'credentials');
      expect(getErrorType(const EmailNotVerified()), 'unverified');
      expect(getErrorType(const UserAlreadyExists()), 'exists');
      expect(getErrorType(const TokenExpired()), 'expired');
      expect(getErrorType(const NotAuthenticated()), 'not_authenticated');
      expect(getErrorType(const InvalidToken()), 'invalid_token');
      expect(
        getErrorType(const UnknownError(message: 'test')),
        'unknown',
      );
      expect(getErrorType(const OAuthCancelled()), 'oauth_cancelled');
    });

    test('toString includes code and message', () {
      const error = UnknownError(message: 'Test error', code: 'TEST_CODE');
      expect(error.toString(), 'AuthError(TEST_CODE): Test error');
    });
  });
}
