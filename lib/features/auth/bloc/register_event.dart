/// Events for [RegisterBloc].
sealed class RegisterEvent {
  const RegisterEvent();
}

/// Email field value changed.
final class RegisterEmailChanged extends RegisterEvent {
  const RegisterEmailChanged(this.email);

  final String email;
}

/// Password field value changed.
final class RegisterPasswordChanged extends RegisterEvent {
  const RegisterPasswordChanged(this.password);

  final String password;
}

/// Confirm password field value changed.
final class RegisterConfirmPasswordChanged extends RegisterEvent {
  const RegisterConfirmPasswordChanged(this.confirmPassword);

  final String confirmPassword;
}

/// Form submitted for registration.
final class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted();
}
