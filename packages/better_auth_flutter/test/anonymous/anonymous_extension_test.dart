import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BetterAuthClientImpl client;

  setUp(() {
    client = BetterAuthClientImpl(
      baseUrl: 'https://api.example.com',
      storage: MemoryStorageImpl(),
    );
  });

  tearDown(() async {
    await client.dispose();
  });

  group('AnonymousExtension', () {
    test('anonymous getter returns Anonymous instance', () {
      final anonymous = client.anonymous;
      expect(anonymous, isA<Anonymous>());
    });

    test('anonymous getter returns same instance on multiple calls', () {
      final anonymous1 = client.anonymous;
      final anonymous2 = client.anonymous;
      expect(identical(anonymous1, anonymous2), true);
    });

    test('different clients have different Anonymous instances', () {
      final client2 = BetterAuthClientImpl(
        baseUrl: 'https://api.example.com',
        storage: MemoryStorageImpl(),
      );

      final anonymous1 = client.anonymous;
      final anonymous2 = client2.anonymous;

      expect(identical(anonymous1, anonymous2), false);

      client2.dispose();
    });
  });
}
