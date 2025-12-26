import 'package:cookie_jar/cookie_jar.dart';

/// Manages persistent cookie storage for HTTP requests.
final class CookieStorage {
  CookieStorage({required String directory})
      : _cookieJar = PersistCookieJar(storage: FileStorage(directory));

  final PersistCookieJar _cookieJar;

  /// The cookie jar for use with Dio.
  CookieJar get cookieJar => _cookieJar;

  /// Clears all stored cookies.
  Future<void> clear() async {
    await _cookieJar.deleteAll();
  }
}
