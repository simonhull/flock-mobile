import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/storage/auth_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show immutable;

/// Context provided to plugins for accessing client capabilities.
///
/// This is the plugin's window into the auth system. It provides
/// everything a plugin needs without exposing implementation details
/// of [BetterAuthClientImpl].
///
/// Plugins receive this in their constructor:
/// ```dart
/// final class MyPlugin {
///   MyPlugin(this._ctx);
///   final PluginContext _ctx;
///
///   TaskEither<AuthError, Data> doSomething() {
///     return TaskEither.tryCatch(() async {
///       _ctx.emitState(const AuthLoading());
///       final response = await _ctx.dio.post('/api/...');
///       // ...
///     }, ErrorMapper.map);
///   }
/// }
/// ```
@immutable
final class PluginContext {
  /// Creates a plugin context.
  ///
  /// Typically created by [BetterAuthClientImpl.pluginContext].
  const PluginContext({
    required this.dio,
    required this.storage,
    required this.emitState,
    required this.currentState,
  });

  /// HTTP client for API requests.
  ///
  /// Pre-configured with base URL, interceptors, and auth headers.
  final Dio dio;

  /// Persistent storage for user and session data.
  final AuthStorage storage;

  /// Emit auth state changes.
  ///
  /// Use this to notify the UI of state transitions:
  /// ```dart
  /// _ctx.emitState(const AuthLoading());
  /// // ... do work ...
  /// _ctx.emitState(Authenticated(user: user, session: session));
  /// ```
  final void Function(AuthState state) emitState;

  /// Get the current auth state.
  ///
  /// Useful for checking if user is authenticated before operations.
  final AuthState Function() currentState;
}
