import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock implementation for testing.
final class MockSSOBrowserHandler implements SSOBrowserHandler {
  Uri? lastAuthorizationUrl;
  Uri? lastCallbackUrl;
  Uri? resultToReturn;
  Exception? errorToThrow;

  @override
  Future<Uri> openAndWaitForCallback({
    required Uri authorizationUrl,
    required Uri callbackUrl,
  }) async {
    lastAuthorizationUrl = authorizationUrl;
    lastCallbackUrl = callbackUrl;

    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

void main() {
  group('SSOBrowserHandler', () {
    test('interface can be implemented', () {
      final handler = MockSSOBrowserHandler();
      expect(handler, isA<SSOBrowserHandler>());
    });

    test('mock handler captures authorization URL', () async {
      final handler = MockSSOBrowserHandler()
        ..resultToReturn = Uri.parse('myapp://callback?code=abc&state=xyz');

      final authUrl = Uri.parse('https://idp.example.com/authorize');
      final callbackUrl = Uri.parse('myapp://callback');

      await handler.openAndWaitForCallback(
        authorizationUrl: authUrl,
        callbackUrl: callbackUrl,
      );

      expect(handler.lastAuthorizationUrl, authUrl);
      expect(handler.lastCallbackUrl, callbackUrl);
    });

    test('mock handler returns callback URI', () async {
      final expectedResult = Uri.parse(
        'myapp://callback?code=authorization_code&state=random_state',
      );
      final handler = MockSSOBrowserHandler()..resultToReturn = expectedResult;

      final result = await handler.openAndWaitForCallback(
        authorizationUrl: Uri.parse('https://idp.example.com/authorize'),
        callbackUrl: Uri.parse('myapp://callback'),
      );

      expect(result, expectedResult);
      expect(result.queryParameters['code'], 'authorization_code');
      expect(result.queryParameters['state'], 'random_state');
    });

    test('mock handler can throw on cancellation', () async {
      final handler = MockSSOBrowserHandler()
        ..errorToThrow = Exception('User cancelled');

      expect(
        () => handler.openAndWaitForCallback(
          authorizationUrl: Uri.parse('https://idp.example.com/authorize'),
          callbackUrl: Uri.parse('myapp://callback'),
        ),
        throwsException,
      );
    });
  });
}
