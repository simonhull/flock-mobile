import 'package:equatable/equatable.dart';

/// Status of the registration form.
enum RegisterStatus {
  /// Initial state, form not yet submitted.
  initial,

  /// Form submission in progress.
  loading,

  /// Registration successful.
  success,

  /// Registration failed with error.
  failure,
}

/// State for [RegisterBloc].
final class RegisterState extends Equatable {
  const RegisterState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.status = RegisterStatus.initial,
    this.errorMessage,
    this.isEmailValid = true,
    this.isPasswordValid = true,
    this.passwordsMatch = true,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final RegisterStatus status;
  final String? errorMessage;
  final bool isEmailValid;
  final bool isPasswordValid;
  final bool passwordsMatch;

  /// Whether the form is valid and can be submitted.
  bool get isFormValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      isEmailValid &&
      isPasswordValid &&
      passwordsMatch;

  RegisterState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    RegisterStatus? status,
    String? errorMessage,
    bool? isEmailValid,
    bool? isPasswordValid,
    bool? passwordsMatch,
  }) {
    return RegisterState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      passwordsMatch: passwordsMatch ?? this.passwordsMatch,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        confirmPassword,
        status,
        errorMessage,
        isEmailValid,
        isPasswordValid,
        passwordsMatch,
      ];
}
