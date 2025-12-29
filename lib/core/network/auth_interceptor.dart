import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';

/// Interceptor that adds Bearer token to authenticated requests.
///
/// Automatically extracts the token from the current auth state
/// and adds it to the Authorization header.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._authClient);

  final BetterAuthClient _authClient;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _extractToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  String? _extractToken() {
    final state = _authClient.currentState;
    return switch (state) {
      Authenticated(:final session) => session.token,
      _ => null,
    };
  }
}
