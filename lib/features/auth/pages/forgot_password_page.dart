import 'package:flock/features/auth/bloc/forgot_password_bloc.dart';
import 'package:flock/features/auth/widgets/auth_button.dart';
import 'package:flock/features/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Forgot password page for requesting password reset email.
final class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: _ForgotPasswordView(),
      ),
    );
  }
}

final class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ForgotPasswordStatus.success:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check your email for reset instructions'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          case ForgotPasswordStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Request failed'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          case ForgotPasswordStatus.initial:
          case ForgotPasswordStatus.loading:
            break;
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowLeft),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Forgot password?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Enter your email and we'll send you\na link to reset your password",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const _EmailField(),
            const SizedBox(height: 32),
            const _SubmitButton(),
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
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      buildWhen: (previous, current) =>
          previous.email != current.email ||
          previous.isEmailValid != current.isEmailValid,
      builder: (context, state) {
        return AuthTextField(
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofocus: true,
          errorText: state.isEmailValid ? null : 'Invalid email address',
          onChanged: (value) => context
              .read<ForgotPasswordBloc>()
              .add(ForgotPasswordEmailChanged(value)),
          onSubmitted: (_) => context
              .read<ForgotPasswordBloc>()
              .add(const ForgotPasswordSubmitted()),
        );
      },
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isFormValid != current.isFormValid,
      builder: (context, state) {
        final isLoading = state.status == ForgotPasswordStatus.loading;

        return AuthButton(
          label: 'Send reset link',
          isLoading: isLoading,
          onPressed: state.isFormValid && !isLoading
              ? () => context
                  .read<ForgotPasswordBloc>()
                  .add(const ForgotPasswordSubmitted())
              : null,
        );
      },
    );
  }
}
