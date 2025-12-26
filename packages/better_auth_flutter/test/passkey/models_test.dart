import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegistrationOptions', () {
    test('creates from JSON', () {
      final json = {
        'challenge': 'abc123',
        'rp': {'id': 'example.com', 'name': 'Example'},
        'user': {
          'id': 'user-123',
          'name': 'test@example.com',
          'displayName': 'Test User',
        },
        'pubKeyCredParams': [
          {'type': 'public-key', 'alg': -7},
          {'type': 'public-key', 'alg': -257},
        ],
        'timeout': 300000,
        'attestation': 'none',
        'authenticatorSelection': {
          'authenticatorAttachment': 'platform',
          'requireResidentKey': false,
          'residentKey': 'preferred',
          'userVerification': 'required',
        },
      };

      final options = RegistrationOptions.fromJson(json);

      expect(options.challenge, 'abc123');
      expect(options.relyingParty.id, 'example.com');
      expect(options.relyingParty.name, 'Example');
      expect(options.user.id, 'user-123');
      expect(options.user.name, 'test@example.com');
      expect(options.user.displayName, 'Test User');
      expect(options.pubKeyCredParams.length, 2);
      expect(options.pubKeyCredParams[0].alg, -7);
      expect(options.timeout, const Duration(milliseconds: 300000));
      expect(options.attestation, 'none');
      expect(options.authenticatorSelection?.userVerification, 'required');
    });
  });

  group('RegistrationResponse', () {
    test('serializes to JSON', () {
      const response = RegistrationResponse(
        id: 'cred-id',
        rawId: 'raw-cred-id',
        type: 'public-key',
        response: AttestationResponse(
          clientDataJSON: 'client-data',
          attestationObject: 'attestation-obj',
          transports: ['internal', 'hybrid'],
        ),
        authenticatorAttachment: 'platform',
      );

      final json = response.toJson();
      final responseJson = json['response'] as Map<String, dynamic>;

      expect(json['id'], 'cred-id');
      expect(json['rawId'], 'raw-cred-id');
      expect(json['type'], 'public-key');
      expect(responseJson['clientDataJSON'], 'client-data');
      expect(responseJson['transports'], ['internal', 'hybrid']);
      expect(json['authenticatorAttachment'], 'platform');
    });
  });

  group('AuthenticationOptions', () {
    test('creates from JSON', () {
      final json = {
        'challenge': 'auth-challenge',
        'timeout': 300000,
        'rpId': 'example.com',
        'allowCredentials': [
          {'id': 'cred-1', 'type': 'public-key', 'transports': ['internal']},
        ],
        'userVerification': 'required',
      };

      final options = AuthenticationOptions.fromJson(json);

      expect(options.challenge, 'auth-challenge');
      expect(options.timeout, const Duration(milliseconds: 300000));
      expect(options.rpId, 'example.com');
      expect(options.allowCredentials.length, 1);
      expect(options.allowCredentials[0].id, 'cred-1');
      expect(options.userVerification, 'required');
    });

    test('handles empty allowCredentials', () {
      final json = {
        'challenge': 'auth-challenge',
        'rpId': 'example.com',
      };

      final options = AuthenticationOptions.fromJson(json);

      expect(options.allowCredentials, isEmpty);
    });
  });

  group('AuthenticationResponse', () {
    test('serializes to JSON', () {
      const response = AuthenticationResponse(
        id: 'cred-id',
        rawId: 'raw-cred-id',
        type: 'public-key',
        response: AssertionResponse(
          clientDataJSON: 'client-data',
          authenticatorData: 'auth-data',
          signature: 'sig-123',
          userHandle: 'user-handle',
        ),
        authenticatorAttachment: 'platform',
      );

      final json = response.toJson();
      final responseJson = json['response'] as Map<String, dynamic>;

      expect(json['id'], 'cred-id');
      expect(json['rawId'], 'raw-cred-id');
      expect(responseJson['signature'], 'sig-123');
      expect(responseJson['userHandle'], 'user-handle');
    });
  });

  group('PasskeyInfo', () {
    test('creates from JSON', () {
      final json = {
        'id': 'pk-123',
        'credentialId': 'cred-abc',
        'name': 'iPhone 15 Pro',
        'createdAt': '2024-01-01T12:00:00.000Z',
        'lastUsedAt': '2024-06-15T10:30:00.000Z',
        'deviceType': 'platform',
      };

      final info = PasskeyInfo.fromJson(json);

      expect(info.id, 'pk-123');
      expect(info.credentialId, 'cred-abc');
      expect(info.name, 'iPhone 15 Pro');
      expect(info.createdAt, DateTime.utc(2024, 1, 1, 12));
      expect(info.lastUsedAt, DateTime.utc(2024, 6, 15, 10, 30));
      expect(info.deviceType, 'platform');
    });

    test('handles null optional fields', () {
      final json = {
        'id': 'pk-123',
        'credentialId': 'cred-abc',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final info = PasskeyInfo.fromJson(json);

      expect(info.name, isNull);
      expect(info.lastUsedAt, isNull);
      expect(info.deviceType, isNull);
    });
  });
}
