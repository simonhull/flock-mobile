import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flock/features/auth/bloc/register_event.dart';
import 'package:flock/features/auth/bloc/register_state.dart';
import 'package:fpdart/fpdart.dart';

export 'package:flock/features/auth/bloc/register_event.dart';
export 'package:flock/features/auth/bloc/register_state.dart';

/// Bloc for the registration form.
///
/// Manages form state, validation, and submission.
/// Uses [droppable] transformer on submit to prevent double-tap.
final class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required BetterAuthClient authClient})
      : _authClient = authClient,
        super(const RegisterState()) {
    on<RegisterEmailChanged>(_onEmailChanged);
    on<RegisterPasswordChanged>(_onPasswordChanged);
    on<RegisterConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<RegisterSubmitted>(_onSubmitted, transformer: droppable());
  }

  final BetterAuthClient _authClient;

  static const _minPasswordLength = 8;
  static final _emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');

  void _onEmailChanged(
    RegisterEmailChanged event,
    Emitter<RegisterState> emit,
  ) {
    final isValid = event.email.isEmpty || _emailRegex.hasMatch(event.email);
    emit(state.copyWith(
      email: event.email,
      isEmailValid: isValid,
      status: RegisterStatus.initial,
    ));
  }

  void _onPasswordChanged(
    RegisterPasswordChanged event,
    Emitter<RegisterState> emit,
  ) {
    final isValid =
        event.password.isEmpty || event.password.length >= _minPasswordLength;
    final passwordsMatch = state.confirmPassword.isEmpty ||
        event.password == state.confirmPassword;

    emit(state.copyWith(
      password: event.password,
      isPasswordValid: isValid,
      passwordsMatch: passwordsMatch,
      status: RegisterStatus.initial,
    ));
  }

  void _onConfirmPasswordChanged(
    RegisterConfirmPasswordChanged event,
    Emitter<RegisterState> emit,
  ) {
    final passwordsMatch =
        event.confirmPassword.isEmpty || state.password == event.confirmPassword;

    emit(state.copyWith(
      confirmPassword: event.confirmPassword,
      passwordsMatch: passwordsMatch,
      status: RegisterStatus.initial,
    ));
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (!state.isFormValid) return;

    emit(state.copyWith(status: RegisterStatus.loading));

    final result = await _authClient
        .signUp(
          email: state.email,
          password: state.password,
        )
        .run();

    switch (result) {
      case Right():
        emit(state.copyWith(status: RegisterStatus.success));
      case Left(value: EmailNotVerified()):
        // User created successfully, just needs to verify email
        emit(state.copyWith(status: RegisterStatus.success));
      case Left(:final value):
        emit(state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: value.message,
        ));
    }
  }
}
