import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/social/oauth_credential.dart';
import 'package:better_auth_flutter/src/social/oauth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock provider for testing.
final class MockOAuthProvider implements OAuthProvider {
  MockOAuthProvider({
    this.providerId = 'mock',
    this.credential,
    this.error,
  });

  @override
  final String providerId;

  final OAuthCredential? credential;
  final AuthError? error;

  @override
  Future<OAuthCredential> authenticate() async {
    if (error != null) throw error!;
    return credential!;
  }
}

void main() {
  group('OAuthProvider', () {
    test('mock provider returns credential on success', () async {
      final provider = MockOAuthProvider(
        providerId: 'google',
        credential: const OAuthCredential(idToken: 'test-token'),
      );

      final result = await provider.authenticate();

      expect(result.idToken, 'test-token');
      expect(provider.providerId, 'google');
    });

    test('mock provider throws error on failure', () async {
      final provider = MockOAuthProvider(
        providerId: 'apple',
        error: const OAuthCancelled(),
      );

      expect(
        provider.authenticate,
        throwsA(isA<OAuthCancelled>()),
      );
    });

    test('mock provider throws provider error', () async {
      final provider = MockOAuthProvider(
        error: const OAuthProviderError(
          provider: 'Google',
          details: 'Sign in failed',
        ),
      );

      expect(
        provider.authenticate,
        throwsA(isA<OAuthProviderError>()),
      );
    });
  });
}
