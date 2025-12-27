import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flock/features/auth/bloc/reset_password_event.dart';
import 'package:flock/features/auth/bloc/reset_password_state.dart';
import 'package:fpdart/fpdart.dart';

export 'package:flock/features/auth/bloc/reset_password_event.dart';
export 'package:flock/features/auth/bloc/reset_password_state.dart';

/// Bloc for the reset password form.
///
/// Manages form state, validation, and password reset with token.
final class ResetPasswordBloc
    extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc({
    required BetterAuthClient authClient,
    required this.token,
  })  : _authClient = authClient,
        super(const ResetPasswordState()) {
    on<ResetPasswordChanged>(_onPasswordChanged);
    on<ResetPasswordConfirmChanged>(_onConfirmPasswordChanged);
    on<ResetPasswordSubmitted>(_onSubmitted, transformer: droppable());
  }

  final BetterAuthClient _authClient;
  final String token;

  static const _minPasswordLength = 8;

  void _onPasswordChanged(
    ResetPasswordChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    final isValid =
        event.password.isEmpty || event.password.length >= _minPasswordLength;
    final passwordsMatch = state.confirmPassword.isEmpty ||
        event.password == state.confirmPassword;

    emit(state.copyWith(
      password: event.password,
      isPasswordValid: isValid,
      passwordsMatch: passwordsMatch,
      status: ResetPasswordStatus.initial,
    ));
  }

  void _onConfirmPasswordChanged(
    ResetPasswordConfirmChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    final passwordsMatch = event.confirmPassword.isEmpty ||
        state.password == event.confirmPassword;

    emit(state.copyWith(
      confirmPassword: event.confirmPassword,
      passwordsMatch: passwordsMatch,
      status: ResetPasswordStatus.initial,
    ));
  }

  Future<void> _onSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    if (!state.isFormValid) return;

    emit(state.copyWith(status: ResetPasswordStatus.loading));

    final result = await _authClient
        .resetPassword(token: token, newPassword: state.password)
        .run();

    switch (result) {
      case Right():
        emit(state.copyWith(status: ResetPasswordStatus.success));
      case Left(:final value):
        emit(state.copyWith(
          status: ResetPasswordStatus.failure,
          errorMessage: value.message,
        ));
    }
  }
}
