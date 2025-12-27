import 'package:equatable/equatable.dart';

/// Status of the forgot password form.
enum ForgotPasswordStatus {
  /// Initial state, form not yet submitted.
  initial,

  /// Form submission in progress.
  loading,

  /// Reset email sent successfully.
  success,

  /// Request failed with error.
  failure,
}

/// State for ForgotPasswordBloc.
final class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.email = '',
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
    this.isEmailValid = true,
  });

  final String email;
  final ForgotPasswordStatus status;
  final String? errorMessage;
  final bool isEmailValid;

  /// Whether the form is valid and can be submitted.
  bool get isFormValid => email.isNotEmpty && isEmailValid;

  ForgotPasswordState copyWith({
    String? email,
    ForgotPasswordStatus? status,
    String? errorMessage,
    bool? isEmailValid,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isEmailValid: isEmailValid ?? this.isEmailValid,
    );
  }

  @override
  List<Object?> get props => [email, status, errorMessage, isEmailValid];
}
