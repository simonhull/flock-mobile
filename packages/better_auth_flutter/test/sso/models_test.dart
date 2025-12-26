import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SSOProvider', () {
    test('creates from JSON with all fields', () {
      final json = {
        'id': 'provider-123',
        'name': 'Acme Corp Okta',
        'type': 'oidc',
        'domain': 'acme.com',
        'organizationId': 'org-456',
        'isEnabled': true,
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final provider = SSOProvider.fromJson(json);

      expect(provider.id, 'provider-123');
      expect(provider.name, 'Acme Corp Okta');
      expect(provider.type, 'oidc');
      expect(provider.domain, 'acme.com');
      expect(provider.organizationId, 'org-456');
      expect(provider.isEnabled, true);
      expect(provider.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
    });

    test('creates from JSON with minimal fields', () {
      final json = {
        'id': 'provider-789',
        'name': 'Google Workspace',
        'type': 'oauth2',
        'isEnabled': false,
        'createdAt': '2024-06-01T00:00:00.000Z',
      };

      final provider = SSOProvider.fromJson(json);

      expect(provider.id, 'provider-789');
      expect(provider.name, 'Google Workspace');
      expect(provider.type, 'oauth2');
      expect(provider.domain, isNull);
      expect(provider.organizationId, isNull);
      expect(provider.isEnabled, false);
    });

    test('handles SAML provider type', () {
      final json = {
        'id': 'saml-provider',
        'name': 'Enterprise SAML',
        'type': 'saml',
        'domain': 'enterprise.org',
        'isEnabled': true,
        'createdAt': '2024-03-20T14:00:00.000Z',
      };

      final provider = SSOProvider.fromJson(json);

      expect(provider.type, 'saml');
    });
  });

  group('SSOAuthorizationResponse', () {
    test('creates from JSON', () {
      final json = {
        'authorizationUrl': 'https://idp.acme.com/authorize?client_id=abc',
        'callbackUrl': 'https://api.example.com/api/auth/sso/callback/provider-123',
        'providerId': 'provider-123',
        'state': 'random-state-token-xyz',
      };

      final response = SSOAuthorizationResponse.fromJson(json);

      expect(
        response.authorizationUrl,
        Uri.parse('https://idp.acme.com/authorize?client_id=abc'),
      );
      expect(
        response.callbackUrl,
        Uri.parse(
          'https://api.example.com/api/auth/sso/callback/provider-123',
        ),
      );
      expect(response.providerId, 'provider-123');
      expect(response.state, 'random-state-token-xyz');
    });

    test('handles complex authorization URL with query params', () {
      final json = {
        'authorizationUrl':
            'https://login.microsoftonline.com/tenant/oauth2/v2.0/authorize?client_id=abc&scope=openid%20profile&state=xyz',
        'callbackUrl': 'myapp://callback',
        'providerId': 'azure-ad',
        'state': 'xyz',
      };

      final response = SSOAuthorizationResponse.fromJson(json);

      expect(response.authorizationUrl.host, 'login.microsoftonline.com');
      expect(
        response.authorizationUrl.queryParameters['client_id'],
        'abc',
      );
      expect(response.callbackUrl.scheme, 'myapp');
    });
  });
}
