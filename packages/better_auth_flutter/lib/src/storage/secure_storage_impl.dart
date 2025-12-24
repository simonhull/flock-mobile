import 'dart:convert';

import 'package:better_auth_flutter/src/models/models.dart';
import 'package:better_auth_flutter/src/storage/auth_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';

/// Secure storage implementation using flutter_secure_storage.
///
/// Stores auth data encrypted on the device.
final class SecureStorageImpl implements AuthStorage {
  SecureStorageImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'better_auth_session';
  static const _userKey = 'better_auth_user';

  @override
  TaskEither<AuthError, Unit> saveSession(Session session) {
    return TaskEither.tryCatch(
      () async {
        final json = jsonEncode(session.toJson());
        await _storage.write(key: _sessionKey, value: json);
        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to save session: $error'),
    );
  }

  @override
  TaskEither<AuthError, Option<Session>> getSession() {
    return TaskEither.tryCatch(
      () async {
        final json = await _storage.read(key: _sessionKey);
        if (json == null) return const None();
        final data = jsonDecode(json) as Map<String, dynamic>;
        return Some(Session.fromJson(data));
      },
      (error, _) => UnknownError(message: 'Failed to read session: $error'),
    );
  }

  @override
  TaskEither<AuthError, Unit> saveUser(User user) {
    return TaskEither.tryCatch(
      () async {
        final json = jsonEncode(user.toJson());
        await _storage.write(key: _userKey, value: json);
        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to save user: $error'),
    );
  }

  @override
  TaskEither<AuthError, Option<User>> getUser() {
    return TaskEither.tryCatch(
      () async {
        final json = await _storage.read(key: _userKey);
        if (json == null) return const None();
        final data = jsonDecode(json) as Map<String, dynamic>;
        return Some(User.fromJson(data));
      },
      (error, _) => UnknownError(message: 'Failed to read user: $error'),
    );
  }

  @override
  TaskEither<AuthError, Unit> clear() {
    return TaskEither.tryCatch(
      () async {
        await Future.wait([
          _storage.delete(key: _sessionKey),
          _storage.delete(key: _userKey),
        ]);
        return unit;
      },
      (error, _) => UnknownError(message: 'Failed to clear storage: $error'),
    );
  }
}
