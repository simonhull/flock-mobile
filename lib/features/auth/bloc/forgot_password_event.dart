/// Events for ForgotPasswordBloc.
sealed class ForgotPasswordEvent {
  const ForgotPasswordEvent();
}

/// Email field value changed.
final class ForgotPasswordEmailChanged extends ForgotPasswordEvent {
  const ForgotPasswordEmailChanged(this.email);

  final String email;
}

/// Form submitted to request password reset.
final class ForgotPasswordSubmitted extends ForgotPasswordEvent {
  const ForgotPasswordSubmitted();
}
