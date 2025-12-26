import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MagicLinkExtension', () {
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

    test('magicLink getter returns MagicLink instance', () {
      final magicLink = client.magicLink;

      expect(magicLink, isA<MagicLink>());
    });

    test('magicLink getter returns same instance on multiple calls', () {
      final magicLink1 = client.magicLink;
      final magicLink2 = client.magicLink;

      expect(identical(magicLink1, magicLink2), true);
    });
  });
}
