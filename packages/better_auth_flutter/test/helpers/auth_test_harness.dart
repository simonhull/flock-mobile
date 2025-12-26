import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'auth_fixtures.dart';

export 'auth_fixtures.dart';

/// Test harness that encapsulates common setup for Better Auth tests.
///
/// Usage:
/// ```dart
/// void main() {
///   final harness = AuthTestHarness();
///
///   setUp(harness.setUp);
///   tearDown(harness.tearDown);
///
///   test('example', () {
///     harness.onPost('/api/auth/login', AuthFixtures.authResponse());
///     // ... test code using harness.client, harness.storage, etc.
///   });
/// }
/// ```
final class AuthTestHarness {
  AuthTestHarness({String baseUrl = AuthFixtures.baseUrl}) : _baseUrl = baseUrl;

  final String _baseUrl;

  late Dio _dio;
  late DioAdapter _dioAdapter;
  late MemoryStorageImpl _storage;
  late BetterAuthClientImpl _client;

  /// The Dio instance for direct access.
  Dio get dio => _dio;

  /// The DioAdapter for mocking HTTP requests.
  DioAdapter get adapter => _dioAdapter;

  /// The in-memory storage implementation.
  MemoryStorageImpl get storage => _storage;

  /// The Better Auth client.
  BetterAuthClientImpl get client => _client;

  /// The plugin context for direct plugin instantiation.
  PluginContext get pluginContext => _client.pluginContext;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _client.authStateChanges;

  /// Set up the test harness. Call this in setUp().
  void setUp() {
    _dio = Dio(BaseOptions(baseUrl: _baseUrl));
    _dioAdapter = DioAdapter(dio: _dio);
    _storage = MemoryStorageImpl();
    _client = BetterAuthClientImpl(
      baseUrl: _baseUrl,
      storage: _storage,
      dio: _dio,
    );
  }

  /// Tear down the test harness. Call this in tearDown().
  Future<void> tearDown() async {
    await _client.dispose();
  }

  /// Mock a POST request.
  void onPost(
    String path,
    dynamic response, {
    int statusCode = 200,
    Map<String, dynamic>? data,
  }) {
    _dioAdapter.onPost(
      path,
      (server) => server.reply(statusCode, response),
      data: data ?? <String, dynamic>{},
    );
  }

  /// Mock a GET request.
  void onGet(
    String path,
    dynamic response, {
    int statusCode = 200,
    Map<String, dynamic>? queryParameters,
  }) {
    _dioAdapter.onGet(
      path,
      (server) => server.reply(statusCode, response),
      queryParameters: queryParameters,
    );
  }

  /// Mock a DELETE request.
  void onDelete(
    String path,
    dynamic response, {
    int statusCode = 200,
    Map<String, dynamic>? data,
  }) {
    _dioAdapter.onDelete(
      path,
      (server) => server.reply(statusCode, response),
      data: data,
    );
  }

  /// Mock a network error.
  void onNetworkError(String path, {String method = 'POST'}) {
    final exception = DioException(
      type: DioExceptionType.connectionError,
      requestOptions: RequestOptions(path: path),
    );

    switch (method.toUpperCase()) {
      case 'GET':
        _dioAdapter.onGet(path, (server) => server.throws(0, exception));
      case 'DELETE':
        _dioAdapter.onDelete(path, (server) => server.throws(0, exception));
      default:
        _dioAdapter.onPost(
          path,
          (server) => server.throws(0, exception),
          data: <String, dynamic>{},
        );
    }
  }

  /// Collect auth state changes during an async operation.
  Future<List<AuthState>> collectStates(
    Future<void> Function() operation, {
    Duration settleDelay = const Duration(milliseconds: 50),
  }) async {
    final states = <AuthState>[];
    final subscription = authStateChanges.listen(states.add);

    await operation();
    await Future<void>.delayed(settleDelay);

    await subscription.cancel();
    return states;
  }
}
