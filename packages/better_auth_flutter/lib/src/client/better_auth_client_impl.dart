import 'dart:async';

import 'package:better_auth_flutter/src/client/better_auth_client.dart';
import 'package:better_auth_flutter/src/client/interceptors/deduplication_interceptor.dart';
import 'package:better_auth_flutter/src/client/interceptors/retry_interceptor.dart';
import 'package:better_auth_flutter/src/client/interceptors/token_refresh_interceptor.dart';
import 'package:better_auth_flutter/src/models/models.dart';
import 'package:better_auth_flutter/src/storage/auth_storage.dart';
import 'package:better_auth_flutter/src/storage/cookie_storage.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';

/// Implementation of [BetterAuthClient] using Dio.
final class BetterAuthClientImpl implements BetterAuthClient {
  /// Creates a new [BetterAuthClientImpl].
  ///
  /// - [baseUrl]: The base URL for the BetterAuth API.
  /// - [storage]: Storage for persisting auth state (user, session).
  /// - [cookieStorage]: Optional cookie storage. If provided, cookies are
  ///   automatically managed and persisted.
  /// - [dio]: Optional Dio instance for testing.
  /// - [enableRetry]: Whether to enable automatic retry with exponential
  ///   backoff. Defaults to true.
  /// - [enableDeduplication]: Whether to prevent duplicate concurrent
  ///   requests. Defaults to true.
  /// - [enableTokenRefresh]: Whether to automatically refresh on 401.
  ///   Defaults to true.
  BetterAuthClientImpl({
    required String baseUrl,
    required AuthStorage storage,
    CookieStorage? cookieStorage,
    Dio? dio,
    bool enableRetry = true,
    bool enableDeduplication = true,
    bool enableTokenRefresh = true,
  })  : _storage = storage,
        _cookieStorage = cookieStorage,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..headers['Content-Type'] = 'application/json'
      ..validateStatus = (status) => status != null && status < 500;

    // Add interceptors in order:
    // 1. Deduplication - prevent duplicate concurrent requests (double-tap)
    // 2. Cookie manager (if provided) - handles cookies
    // 3. Auth interceptor - adds Bearer token header
    // 4. Token refresh - handles 401 by attempting session refresh
    // 5. Retry interceptor - retries on transient failures
    if (enableDeduplication && dio == null) {
      _dio.interceptors.add(DeduplicationInterceptor());
    }
    if (cookieStorage != null) {
      _dio.interceptors.add(CookieManager(cookieStorage.cookieJar));
    }
    _dio.interceptors.add(_createAuthInterceptor());
    if (enableTokenRefresh && dio == null) {
      _dio.interceptors.add(
        TokenRefreshInterceptor(
          dio: _dio,
          storage: storage,
          emitState: _stateController.add,
        ),
      );
    }
    if (enableRetry && dio == null) {
      _dio.interceptors.add(RetryInterceptor(dio: _dio));
    }
  }

  /// Creates a client with cookie support using a persistent cookie jar.
  ///
  /// This is the recommended factory for production use.
  static Future<BetterAuthClientImpl> withCookies({
    required String baseUrl,
    required AuthStorage storage,
    required String cookieDirectory,
  }) async {
    final cookieStorage = CookieStorage(directory: cookieDirectory);
    return BetterAuthClientImpl(
      baseUrl: baseUrl,
      storage: storage,
      cookieStorage: cookieStorage,
    );
  }

  final AuthStorage _storage;
  final CookieStorage? _cookieStorage;
  final Dio _dio;
  final _stateController =
      BehaviorSubject<AuthState>.seeded(const AuthInitial());

  // Package-internal accessors for extensions (e.g., SocialAuthExtension).
  // Not part of public API - do not use outside this package.

  /// Internal storage access for package extensions.
  AuthStorage get internalStorage => _storage;

  /// Internal Dio access for package extensions.
  Dio get internalDio => _dio;

  /// Internal state controller for package extensions.
  BehaviorSubject<AuthState> get internalStateController => _stateController;

  @override
  Stream<AuthState> get authStateChanges => _stateController.stream;

  @override
  AuthState get currentState => _stateController.value;

  @override
  User? get currentUser => switch (currentState) {
        Authenticated(:final user) => user,
        _ => null,
      };

  // === Lifecycle ===

  @override
  TaskEither<AuthError, Unit> initialize() {
    return TaskEither.tryCatch(
      () async {
        _stateController.add(const AuthLoading());

        final sessionResult = await _storage.getSession().run();
        final userResult = await _storage.getUser().run();

        switch ((sessionResult, userResult)) {
          case (
              Right(value: Some(:final value)),
              Right(value: Some(value: final user))
            ) when value.isValid:
            _stateController.add(Authenticated(user: user, session: value));
          case _:
            await _clearAuth();
        }

        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to initialize: $error'),
    );
  }

  @override
  Future<void> dispose() async {
    await _stateController.close();
  }

  // === Email/Password Authentication ===

  @override
  TaskEither<AuthError, Authenticated> signUp({
    required String email,
    required String password,
    String? name,
  }) {
    return _authRequest(
      path: '/api/auth/sign-up/email',
      data: {
        'email': email,
        'password': password,
        'name': name ?? email.split('@').first,
      },
    );
  }

  @override
  TaskEither<AuthError, Authenticated> signIn({
    required String email,
    required String password,
  }) {
    return _authRequest(
      path: '/api/auth/sign-in/email',
      data: {'email': email, 'password': password},
    );
  }

  @override
  TaskEither<AuthError, Unit> signOut() {
    return TaskEither.tryCatch(
      () async {
        try {
          await _dio.post<dynamic>('/api/auth/sign-out');
        } on DioException {
          // Ignore server errors on sign out
        }
        await _clearAuth();
        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to sign out: $error'),
    );
  }

  // === Email Verification ===

  @override
  TaskEither<AuthError, Unit> sendVerificationEmail({
    String? email,
    String? callbackUrl,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post<dynamic>(
          '/api/auth/send-verification-email',
          data: {
            if (email != null) 'email': email,
            if (callbackUrl != null) 'callbackURL': callbackUrl,
          },
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        return unit;
      },
      _mapError,
    );
  }

  @override
  TaskEither<AuthError, Unit> verifyEmail({required String token}) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.get<dynamic>(
          '/api/auth/verify-email',
          queryParameters: {'token': token},
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        // Refresh user to get updated emailVerified status
        await _refreshUser();

        return unit;
      },
      _mapError,
    );
  }

  // === Password Reset ===

  @override
  TaskEither<AuthError, Unit> forgotPassword({required String email}) {
    return TaskEither.tryCatch(
      () async {
        // Always succeeds - doesn't reveal if email exists
        await _dio.post<dynamic>(
          '/api/auth/forget-password',
          data: {'email': email, 'redirectTo': '/reset-password'},
        );
        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to send reset email: $error'),
    );
  }

  @override
  TaskEither<AuthError, Unit> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post<dynamic>(
          '/api/auth/reset-password',
          data: {'token': token, 'newPassword': newPassword},
        );

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        return unit;
      },
      _mapError,
    );
  }

  // === Session ===

  @override
  TaskEither<AuthError, Session> getSession() {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.get<dynamic>('/api/auth/get-session');

        if (response.statusCode != 200) {
          throw _mapStatusToError(response);
        }

        final data = response.data as Map<String, dynamic>;
        return Session.fromJson(data['session'] as Map<String, dynamic>);
      },
      _mapError,
    );
  }

  // === Private Helpers ===

  /// Creates an interceptor that adds the Bearer token header.
  ///
  /// Note: 401 handling is done by [TokenRefreshInterceptor], which attempts
  /// to refresh the session before clearing auth.
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final result = await _storage.getSession().run();

        switch (result) {
          case Right(value: Some(:final value)) when value.isValid:
            options.headers['Authorization'] = 'Bearer ${value.token}';
          case _:
            break;
        }

        handler.next(options);
      },
    );
  }

  TaskEither<AuthError, Authenticated> _authRequest({
    required String path,
    required Map<String, dynamic> data,
  }) {
    return TaskEither.tryCatch(
      () async {
        _stateController.add(const AuthLoading());

        final response = await _dio.post<dynamic>(path, data: data);

        if (response.statusCode != 200) {
          _stateController.add(const Unauthenticated());
          throw _mapStatusToError(response);
        }

        final responseData = response.data as Map<String, dynamic>;
        final user = User.fromJson(
          responseData['user'] as Map<String, dynamic>,
        );
        final session = Session.fromJson(
          responseData['session'] as Map<String, dynamic>,
        );

        await _storage.saveUser(user).run();
        await _storage.saveSession(session).run();

        final state = Authenticated(user: user, session: session);
        _stateController.add(state);

        return state;
      },
      (error, stackTrace) {
        _stateController.add(const Unauthenticated());
        return _mapError(error, stackTrace);
      },
    );
  }

  Future<void> _clearAuth() async {
    await _storage.clear().run();
    await _cookieStorage?.clear();
    _stateController.add(const Unauthenticated());
  }

  Future<void> _refreshUser() async {
    try {
      final response = await _dio.get<dynamic>('/api/auth/get-session');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['user'] != null) {
          final user = User.fromJson(data['user'] as Map<String, dynamic>);
          await _storage.saveUser(user).run();

          final sessionResult = await _storage.getSession().run();
          switch (sessionResult) {
            case Right(value: Some(:final value)):
              _stateController.add(Authenticated(user: user, session: value));
            case _:
              break;
          }
        }
      }
    } on DioException {
      // Ignore refresh errors
    }
  }

  AuthError _mapStatusToError(Response<dynamic> response) {
    final data = response.data;
    final statusCode = response.statusCode;

    String? code;
    String? message;

    if (data is Map<String, dynamic>) {
      code = data['code'] as String?;
      message = data['message'] as String?;
    }

    return switch (statusCode) {
      401 => const InvalidCredentials(),
      403 when code == 'EMAIL_NOT_VERIFIED' => const EmailNotVerified(),
      409 => const UserAlreadyExists(),
      400 when code == 'INVALID_TOKEN' => const InvalidToken(),
      _ => UnknownError(message: message ?? 'Request failed', code: code),
    };
  }

  AuthError _mapError(Object error, StackTrace stackTrace) {
    if (error is AuthError) return error;

    if (error is DioException) {
      final isConnectionError =
          error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout;

      if (isConnectionError) {
        return const NetworkError();
      }

      if (error.response != null) {
        return _mapStatusToError(error.response!);
      }
    }

    return UnknownError(message: error.toString());
  }
}
