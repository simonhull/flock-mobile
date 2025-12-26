import 'dart:io';

import 'package:better_auth_flutter/src/storage/cookie_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CookieStorage', () {
    late Directory tempDir;
    late CookieStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cookie_test_');
      storage = CookieStorage(directory: tempDir.path);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('provides a cookie jar', () {
      expect(storage.cookieJar, isNotNull);
    });

    test('persists cookies to disk', () async {
      final uri = Uri.parse('https://example.com');
      final cookie = Cookie('session', 'abc123');

      await storage.cookieJar.saveFromResponse(uri, [cookie]);

      // Create new storage pointing to same directory
      final storage2 = CookieStorage(directory: tempDir.path);
      final cookies = await storage2.cookieJar.loadForRequest(uri);

      expect(cookies, hasLength(1));
      expect(cookies.first.name, 'session');
      expect(cookies.first.value, 'abc123');
    });

    test('clear removes all cookies', () async {
      final uri = Uri.parse('https://example.com');
      final cookie = Cookie('session', 'abc123');

      await storage.cookieJar.saveFromResponse(uri, [cookie]);
      await storage.clear();

      final cookies = await storage.cookieJar.loadForRequest(uri);
      expect(cookies, isEmpty);
    });
  });
}
