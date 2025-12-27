/// Events for ResetPasswordBloc.
sealed class ResetPasswordEvent {
  const ResetPasswordEvent();
}

/// Password field value changed.
final class ResetPasswordChanged extends ResetPasswordEvent {
  const ResetPasswordChanged(this.password);

  final String password;
}

/// Confirm password field value changed.
final class ResetPasswordConfirmChanged extends ResetPasswordEvent {
  const ResetPasswordConfirmChanged(this.confirmPassword);

  final String confirmPassword;
}

/// Form submitted to reset password.
final class ResetPasswordSubmitted extends ResetPasswordEvent {
  const ResetPasswordSubmitted();
}
