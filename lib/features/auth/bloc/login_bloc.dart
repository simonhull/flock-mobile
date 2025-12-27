import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flock/features/auth/bloc/login_event.dart';
import 'package:flock/features/auth/bloc/login_state.dart';
import 'package:fpdart/fpdart.dart';

export 'package:flock/features/auth/bloc/login_event.dart';
export 'package:flock/features/auth/bloc/login_state.dart';

/// Bloc for the login form.
///
/// Manages form state, validation, and submission.
/// Uses [droppable] transformer on submit to prevent double-tap.
final class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required BetterAuthClient authClient})
      : _authClient = authClient,
        super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  final BetterAuthClient _authClient;

  static final _emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');

  void _onEmailChanged(
    LoginEmailChanged event,
    Emitter<LoginState> emit,
  ) {
    final isValid = event.email.isEmpty || _emailRegex.hasMatch(event.email);
    emit(state.copyWith(
      email: event.email,
      isEmailValid: isValid,
      status: LoginStatus.initial,
    ));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(
      password: event.password,
      isPasswordValid: true,
      status: LoginStatus.initial,
    ));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isFormValid) return;

    emit(state.copyWith(status: LoginStatus.loading));

    final result = await _authClient
        .signIn(
          email: state.email,
          password: state.password,
        )
        .run();

    switch (result) {
      case Right():
        emit(state.copyWith(status: LoginStatus.success));
      case Left(:final value):
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: value.message,
        ));
    }
  }
}
