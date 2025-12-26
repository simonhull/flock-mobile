import 'package:better_auth_flutter/src/social/oauth_credential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthCredential', () {
    test('creates with required idToken only', () {
      const cred = OAuthCredential(idToken: 'token123');

      expect(cred.idToken, 'token123');
      expect(cred.accessToken, isNull);
      expect(cred.nonce, isNull);
    });

    test('creates with all fields', () {
      const cred = OAuthCredential(
        idToken: 'id-token',
        accessToken: 'access-token',
        nonce: 'nonce123',
      );

      expect(cred.idToken, 'id-token');
      expect(cred.accessToken, 'access-token');
      expect(cred.nonce, 'nonce123');
    });

    test('equality based on all fields', () {
      const cred1 = OAuthCredential(
        idToken: 'token',
        accessToken: 'access',
        nonce: 'nonce',
      );
      const cred2 = OAuthCredential(
        idToken: 'token',
        accessToken: 'access',
        nonce: 'nonce',
      );
      const cred3 = OAuthCredential(idToken: 'different');

      expect(cred1, equals(cred2));
      expect(cred1, isNot(equals(cred3)));
    });

    test('hashCode consistent with equality', () {
      const cred1 = OAuthCredential(idToken: 'token', accessToken: 'access');
      const cred2 = OAuthCredential(idToken: 'token', accessToken: 'access');

      expect(cred1.hashCode, equals(cred2.hashCode));
    });
  });
}
