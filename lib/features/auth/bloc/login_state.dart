import 'package:equatable/equatable.dart';

/// Status of the login form.
enum LoginStatus {
  /// Initial state, form not yet submitted.
  initial,

  /// Form submission in progress.
  loading,

  /// Login successful.
  success,

  /// Login failed with error.
  failure,
}

/// State for [LoginBloc].
final class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.isEmailValid = true,
    this.isPasswordValid = true,
  });

  final String email;
  final String password;
  final LoginStatus status;
  final String? errorMessage;
  final bool isEmailValid;
  final bool isPasswordValid;

  /// Whether the form is valid and can be submitted.
  bool get isFormValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      isEmailValid &&
      isPasswordValid;

  LoginState copyWith({
    String? email,
    String? password,
    LoginStatus? status,
    String? errorMessage,
    bool? isEmailValid,
    bool? isPasswordValid,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        status,
        errorMessage,
        isEmailValid,
        isPasswordValid,
      ];
}
