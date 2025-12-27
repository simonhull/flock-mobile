import 'package:flock/features/auth/bloc/login_bloc.dart';
import 'package:flock/features/auth/widgets/auth_button.dart';
import 'package:flock/features/auth/widgets/auth_text_field.dart';
import 'package:flock/features/auth/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Login page for email/password authentication.
final class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: _LoginView(),
      ),
    );
  }
}

final class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.success:
            // Navigation handled by router redirect
            break;
          case LoginStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Login failed'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          case LoginStatus.initial:
          case LoginStatus.loading:
            break;
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const _EmailField(),
            const SizedBox(height: 16),
            const _PasswordField(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 24),
            const _SubmitButton(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _EmailField extends StatelessWidget {
  const _EmailField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) =>
          previous.email != current.email ||
          previous.isEmailValid != current.isEmailValid,
      builder: (context, state) {
        return AuthTextField(
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          errorText: state.isEmailValid ? null : 'Invalid email address',
          onChanged: (value) =>
              context.read<LoginBloc>().add(LoginEmailChanged(value)),
        );
      },
    );
  }
}

final class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) =>
          previous.password != current.password ||
          previous.isPasswordValid != current.isPasswordValid,
      builder: (context, state) {
        return PasswordField(
          label: 'Password',
          textInputAction: TextInputAction.done,
          errorText: state.isPasswordValid ? null : 'Password required',
          onChanged: (value) =>
              context.read<LoginBloc>().add(LoginPasswordChanged(value)),
          onSubmitted: (_) =>
              context.read<LoginBloc>().add(const LoginSubmitted()),
        );
      },
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isFormValid != current.isFormValid,
      builder: (context, state) {
        final isLoading = state.status == LoginStatus.loading;

        return AuthButton(
          label: 'Sign in',
          isLoading: isLoading,
          onPressed: state.isFormValid && !isLoading
              ? () => context.read<LoginBloc>().add(const LoginSubmitted())
              : null,
        );
      },
    );
  }
}
