import 'package:equatable/equatable.dart';

/// Status of the reset password form.
enum ResetPasswordStatus {
  /// Initial state, form not yet submitted.
  initial,

  /// Form submission in progress.
  loading,

  /// Password reset successful.
  success,

  /// Password reset failed with error.
  failure,
}

/// State for ResetPasswordBloc.
final class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.password = '',
    this.confirmPassword = '',
    this.status = ResetPasswordStatus.initial,
    this.errorMessage,
    this.isPasswordValid = true,
    this.passwordsMatch = true,
  });

  final String password;
  final String confirmPassword;
  final ResetPasswordStatus status;
  final String? errorMessage;
  final bool isPasswordValid;
  final bool passwordsMatch;

  /// Whether the form is valid and can be submitted.
  bool get isFormValid =>
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      isPasswordValid &&
      passwordsMatch;

  ResetPasswordState copyWith({
    String? password,
    String? confirmPassword,
    ResetPasswordStatus? status,
    String? errorMessage,
    bool? isPasswordValid,
    bool? passwordsMatch,
  }) {
    return ResetPasswordState(
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      passwordsMatch: passwordsMatch ?? this.passwordsMatch,
    );
  }

  @override
  List<Object?> get props => [
        password,
        confirmPassword,
        status,
        errorMessage,
        isPasswordValid,
        passwordsMatch,
      ];
}
