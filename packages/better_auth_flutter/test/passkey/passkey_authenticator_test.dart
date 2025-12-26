import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock implementation for testing.
final class MockPasskeyAuthenticator implements PasskeyAuthenticator {
  bool isSupportedResult = true;
  bool isAvailableResult = true;
  RegistrationResponse? createCredentialResult;
  AuthenticationResponse? getAssertionResult;
  Exception? errorToThrow;

  @override
  Future<bool> isSupported() async => isSupportedResult;

  @override
  Future<bool> isAvailable() async => isAvailableResult;

  @override
  Future<RegistrationResponse> createCredential(
    RegistrationOptions options,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return createCredentialResult!;
  }

  @override
  Future<AuthenticationResponse> getAssertion(
    AuthenticationOptions options,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return getAssertionResult!;
  }
}

void main() {
  group('PasskeyAuthenticator', () {
    test('interface can be implemented', () {
      final authenticator = MockPasskeyAuthenticator();
      expect(authenticator, isA<PasskeyAuthenticator>());
    });

    test('mock authenticator works in tests', () async {
      final authenticator = MockPasskeyAuthenticator()
        ..isSupportedResult = true
        ..isAvailableResult = true
        ..createCredentialResult = const RegistrationResponse(
          id: 'test-id',
          rawId: 'test-raw-id',
          type: 'public-key',
          response: AttestationResponse(
            clientDataJSON: 'client-data',
            attestationObject: 'attestation',
          ),
        );

      expect(await authenticator.isSupported(), true);
      expect(await authenticator.isAvailable(), true);

      const options = RegistrationOptions(
        challenge: 'test-challenge',
        relyingParty: RelyingParty(id: 'test.com', name: 'Test'),
        user: WebAuthnUserInfo(
          id: 'user-123',
          name: 'test@test.com',
          displayName: 'Test User',
        ),
        pubKeyCredParams: [],
      );

      final result = await authenticator.createCredential(options);
      expect(result.id, 'test-id');
    });
  });
}
