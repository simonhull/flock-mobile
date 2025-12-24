import 'package:better_auth_flutter/src/models/models.dart';
import 'package:better_auth_flutter/src/storage/auth_storage.dart';
import 'package:fpdart/fpdart.dart';

/// In-memory storage implementation for testing.
///
/// Does not persist data between sessions.
final class MemoryStorageImpl implements AuthStorage {
  Session? _session;
  User? _user;

  @override
  TaskEither<AuthError, Unit> saveSession(Session session) {
    return TaskEither<AuthError, Unit>.of(unit).map((_) {
      _session = session;
      return unit;
    });
  }

  @override
  TaskEither<AuthError, Option<Session>> getSession() {
    return TaskEither<AuthError, Option<Session>>.of(
      Option.fromNullable(_session),
    );
  }

  @override
  TaskEither<AuthError, Unit> saveUser(User user) {
    return TaskEither<AuthError, Unit>.of(unit).map((_) {
      _user = user;
      return unit;
    });
  }

  @override
  TaskEither<AuthError, Option<User>> getUser() {
    return TaskEither<AuthError, Option<User>>.of(Option.fromNullable(_user));
  }

  @override
  TaskEither<AuthError, Unit> clear() {
    return TaskEither<AuthError, Unit>.of(unit).map((_) {
      _session = null;
      _user = null;
      return unit;
    });
  }
}
