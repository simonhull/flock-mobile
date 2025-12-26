import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TwoFactorExtension', () {
    late BetterAuthClientImpl client;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      client = BetterAuthClientImpl(
        baseUrl: 'https://api.example.com',
        storage: MemoryStorageImpl(),
        dio: dio,
      );
    });

    tearDown(() async {
      await client.dispose();
    });

    test('twoFactor getter returns TwoFactor instance', () {
      final twoFactor = client.twoFactor;

      expect(twoFactor, isA<TwoFactor>());
    });

    test('twoFactor getter returns same instance on multiple calls', () {
      final twoFactor1 = client.twoFactor;
      final twoFactor2 = client.twoFactor;

      // Should be the same instance (cached)
      expect(identical(twoFactor1, twoFactor2), true);
    });
  });
}
