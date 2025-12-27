import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:equatable/equatable.dart';

/// Status of the global auth state.
enum AuthStatus {
  /// Initial state before checking stored session.
  unknown,

  /// User is authenticated with valid session.
  authenticated,

  /// User is not authenticated.
  unauthenticated,
}

/// Global authentication state.
///
/// This state is managed by [AuthBloc] and reflects the current
/// authentication status of the user across the app.
final class AuthBlocState extends Equatable {
  const AuthBlocState({
    this.status = AuthStatus.unknown,
    this.user,
  });

  const AuthBlocState.unknown() : this();

  const AuthBlocState.authenticated(User user)
      : this(status: AuthStatus.authenticated, user: user);

  const AuthBlocState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final User? user;

  @override
  List<Object?> get props => [status, user];
}
