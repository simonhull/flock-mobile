/// Events for [LoginBloc].
sealed class LoginEvent {
  const LoginEvent();
}

/// Email field value changed.
final class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.email);

  final String email;
}

/// Password field value changed.
final class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.password);

  final String password;
}

/// Form submitted for sign in.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}
