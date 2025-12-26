import 'dart:async';

import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:better_auth_flutter/src/storage/auth_storage.dart';
import 'package:dio/dio.dart';

/// Interceptor that handles 401 errors by attempting to refresh the session.
///
/// When a request fails with 401:
/// 1. If it's an auth endpoint (sign-in/sign-up/sign-out), pass through
/// 2. Otherwise, attempt to refresh by calling `/api/auth/get-session`
/// 3. If refresh succeeds, retry the original request
/// 4. If refresh fails, emit [Unauthenticated] and clear storage
///
/// Multiple simultaneous 401 errors are coalesced into a single refresh
/// attempt to avoid thundering herd on the auth server.
final class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required AuthStorage storage,
    required void Function(AuthState) emitState,
  })  : _dio = dio,
        _storage = storage,
        _emitState = emitState;

  final Dio _dio;
  final AuthStorage _storage;
  final void Function(AuthState) _emitState;

  /// Completer for coalescing simultaneous refresh attempts.
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 errors
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't attempt refresh for auth endpoints
    if (_isAuthEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    // Attempt to refresh the session
    final refreshed = await _attemptRefresh();

    if (refreshed) {
      // Retry the original request
      try {
        final response = await _dio.fetch<dynamic>(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }

    // Refresh failed — user needs to re-authenticate
    _emitState(const Unauthenticated());
    await _storage.clear().run();
    return handler.next(err);
  }

  Future<bool> _attemptRefresh() async {
    // If a refresh is already in progress, wait for it
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final response = await _dio.get<dynamic>('/api/auth/get-session');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Parse and save the refreshed session
        if (data['session'] != null && data['user'] != null) {
          final session = Session.fromJson(
            data['session'] as Map<String, dynamic>,
          );
          final user = User.fromJson(
            data['user'] as Map<String, dynamic>,
          );

          await _storage.saveSession(session).run();
          await _storage.saveUser(user).run();

          _refreshCompleter!.complete(true);
          return true;
        }
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Check if the path is an authentication endpoint.
  ///
  /// These endpoints should not trigger refresh logic because:
  /// - sign-in/sign-up 401 means invalid credentials
  /// - sign-out 401 is benign (already signed out)
  /// - get-session 401 means session is invalid (would cause infinite loop)
  bool _isAuthEndpoint(String path) {
    return path.contains('/sign-in') ||
        path.contains('/sign-up') ||
        path.contains('/sign-out') ||
        path.contains('/get-session');
  }
}
