import 'package:flock/features/auth/bloc/reset_password_bloc.dart';
import 'package:flock/features/auth/widgets/auth_button.dart';
import 'package:flock/features/auth/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Reset password page for setting a new password via token.
final class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: _ResetPasswordView(),
      ),
    );
  }
}

final class _ResetPasswordView extends StatelessWidget {
  const _ResetPasswordView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResetPasswordBloc, ResetPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ResetPasswordStatus.success:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset successfully!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/login');
          case ResetPasswordStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Password reset failed'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          case ResetPasswordStatus.initial:
          case ResetPasswordStatus.loading:
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
              'Reset password',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your new password',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const _PasswordField(),
            const SizedBox(height: 16),
            const _ConfirmPasswordField(),
            const SizedBox(height: 32),
            const _SubmitButton(),
          ],
        ),
      ),
    );
  }
}

final class _PasswordField extends StatelessWidget {
  const _PasswordField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      buildWhen: (previous, current) =>
          previous.password != current.password ||
          previous.isPasswordValid != current.isPasswordValid,
      builder: (context, state) {
        return PasswordField(
          label: 'New password',
          textInputAction: TextInputAction.next,
          autofocus: true,
          errorText:
              state.isPasswordValid ? null : 'Password must be 8+ characters',
          onChanged: (value) => context
              .read<ResetPasswordBloc>()
              .add(ResetPasswordChanged(value)),
        );
      },
    );
  }
}

final class _ConfirmPasswordField extends StatelessWidget {
  const _ConfirmPasswordField();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      buildWhen: (previous, current) =>
          previous.confirmPassword != current.confirmPassword ||
          previous.passwordsMatch != current.passwordsMatch,
      builder: (context, state) {
        return PasswordField(
          label: 'Confirm new password',
          textInputAction: TextInputAction.done,
          errorText: state.passwordsMatch ? null : 'Passwords do not match',
          onChanged: (value) => context
              .read<ResetPasswordBloc>()
              .add(ResetPasswordConfirmChanged(value)),
          onSubmitted: (_) => context
              .read<ResetPasswordBloc>()
              .add(const ResetPasswordSubmitted()),
        );
      },
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isFormValid != current.isFormValid,
      builder: (context, state) {
        final isLoading = state.status == ResetPasswordStatus.loading;

        return AuthButton(
          label: 'Reset password',
          isLoading: isLoading,
          onPressed: state.isFormValid && !isLoading
              ? () => context
                  .read<ResetPasswordBloc>()
                  .add(const ResetPasswordSubmitted())
              : null,
        );
      },
    );
  }
}
