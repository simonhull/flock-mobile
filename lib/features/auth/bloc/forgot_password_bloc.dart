import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flock/features/auth/bloc/forgot_password_event.dart';
import 'package:flock/features/auth/bloc/forgot_password_state.dart';
import 'package:fpdart/fpdart.dart';

export 'package:flock/features/auth/bloc/forgot_password_event.dart';
export 'package:flock/features/auth/bloc/forgot_password_state.dart';

/// Bloc for the forgot password form.
///
/// Manages form state, validation, and password reset request.
final class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({required BetterAuthClient authClient})
      : _authClient = authClient,
        super(const ForgotPasswordState()) {
    on<ForgotPasswordEmailChanged>(_onEmailChanged);
    on<ForgotPasswordSubmitted>(_onSubmitted, transformer: droppable());
  }

  final BetterAuthClient _authClient;

  static final _emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');

  void _onEmailChanged(
    ForgotPasswordEmailChanged event,
    Emitter<ForgotPasswordState> emit,
  ) {
    final isValid = event.email.isEmpty || _emailRegex.hasMatch(event.email);
    emit(state.copyWith(
      email: event.email,
      isEmailValid: isValid,
      status: ForgotPasswordStatus.initial,
    ));
  }

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (!state.isFormValid) return;

    emit(state.copyWith(status: ForgotPasswordStatus.loading));

    final result = await _authClient.forgotPassword(email: state.email).run();

    switch (result) {
      case Right():
        emit(state.copyWith(status: ForgotPasswordStatus.success));
      case Left(:final value):
        emit(state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: value.message,
        ));
    }
  }
}
