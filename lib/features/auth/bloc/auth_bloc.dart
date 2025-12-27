import 'dart:async';

import 'package:better_auth_flutter/better_auth_flutter.dart' as ba;
import 'package:bloc/bloc.dart';
import 'package:flock/features/auth/bloc/auth_event.dart';
import 'package:flock/features/auth/bloc/auth_state.dart';

export 'package:flock/features/auth/bloc/auth_event.dart';
export 'package:flock/features/auth/bloc/auth_state.dart';

/// Global authentication bloc.
///
/// Listens to [BetterAuthClient.authStateChanges] and translates them
/// into [AuthBlocState]. Does not perform auth operations directly -
/// those are handled by page-specific blocs (LoginBloc, RegisterBloc, etc.).
final class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  AuthBloc({required ba.BetterAuthClient authClient})
      : _authClient = authClient,
        super(const AuthBlocState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    _authSubscription = _authClient.authStateChanges.listen(
      (authState) => add(AuthStateChanged(authState)),
    );
  }

  final ba.BetterAuthClient _authClient;
  StreamSubscription<ba.AuthState>? _authSubscription;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    await _authClient.initialize().run();
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthBlocState> emit,
  ) async {
    await _authClient.signOut().run();
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthBlocState> emit,
  ) {
    switch (event.authState) {
      case ba.Authenticated(:final user):
        emit(AuthBlocState.authenticated(user));
      case ba.Unauthenticated():
        emit(const AuthBlocState.unauthenticated());
      case ba.AuthInitial():
      case ba.AuthLoading():
        // Keep current state during loading/initial
        break;
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
