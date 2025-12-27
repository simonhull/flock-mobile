import 'package:flock/features/auth/bloc/register_bloc.dart';
import 'package:flock/features/auth/widgets/auth_button.dart';
import 'package:flock/features/auth/widgets/auth_text_field.dart';
import 'package:flock/features/auth/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Registration page for new user accounts.
final class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: _RegisterView(),
      ),
    );
  }
}

final class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case RegisterStatus.success:
            final email = Uri.encodeComponent(state.email);
            context.go('/check-email?email=$email');
          case RegisterStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Registration failed'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          case RegisterStatus.initial:
          case RegisterStatus.loading:
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
              'Create account',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your identity. Your communities. Your journey.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const _EmailField(),
            const SizedBox(height: 16),
            const _PasswordField(),
            const SizedBox(height: 16),
            const _ConfirmPasswordField(),
            const SizedBox(height: 32),
            const _SubmitButton(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Sign in'),
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
    return BlocBuilder<RegisterBloc, RegisterState>(
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
              context.read<RegisterBloc>().add(RegisterEmailChanged(value)),
        );
      },
    );
  }
}

final class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) =>
          previous.password != current.password ||
          previous.isPasswordValid != current.isPasswordValid,
      builder: (context, state) {
        return PasswordField(
          label: 'Password',
          textInputAction: TextInputAction.next,
          errorText:
              state.isPasswordValid ? null : 'Password must be 8+ characters',
          onChanged: (value) =>
              context.read<RegisterBloc>().add(RegisterPasswordChanged(value)),
        );
      },
    );
  }
}

final class _ConfirmPasswordField extends StatelessWidget {
  const _ConfirmPasswordField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) =>
          previous.confirmPassword != current.confirmPassword ||
          previous.passwordsMatch != current.passwordsMatch,
      builder: (context, state) {
        return PasswordField(
          label: 'Confirm password',
          textInputAction: TextInputAction.done,
          errorText: state.passwordsMatch ? null : 'Passwords do not match',
          onChanged: (value) => context
              .read<RegisterBloc>()
              .add(RegisterConfirmPasswordChanged(value)),
          onSubmitted: (_) =>
              context.read<RegisterBloc>().add(const RegisterSubmitted()),
        );
      },
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isFormValid != current.isFormValid,
      builder: (context, state) {
        final isLoading = state.status == RegisterStatus.loading;

        return AuthButton(
          label: 'Create account',
          isLoading: isLoading,
          onPressed: state.isFormValid && !isLoading
              ? () => context.read<RegisterBloc>().add(const RegisterSubmitted())
              : null,
        );
      },
    );
  }
}
