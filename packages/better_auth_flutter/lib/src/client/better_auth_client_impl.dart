import 'dart:async';

import 'package:better_auth_flutter/src/client/better_auth_client.dart';
import 'package:better_auth_flutter/src/models/models.dart';
import 'package:better_auth_flutter/src/storage/auth_storage.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rxdart/rxdart.dart';

/// Implementation of [BetterAuthClient] using Dio.
final class BetterAuthClientImpl implements BetterAuthClient {
  BetterAuthClientImpl({
    required String baseUrl,
    required AuthStorage storage,
    Dio? dio,
  })  : _storage = storage,
        _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..headers['Content-Type'] = 'application/json'
      ..validateStatus = (status) => status != null && status < 500;

    _dio.interceptors.add(_createAuthInterceptor());
  }

  final AuthStorage _storage;
  final Dio _dio;
  final _stateController =
      BehaviorSubject<AuthState>.seeded(const AuthInitial());

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
  TaskEither<AuthError, Unit> sendVerificationEmail() {
    return TaskEither.tryCatch(
      () async {
        final response = await _dio.post<dynamic>(
          '/api/auth/send-verification-email',
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
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _clearAuth();
        }
        handler.next(error);
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
