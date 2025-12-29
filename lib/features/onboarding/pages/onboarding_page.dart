import 'package:flock/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:flock/features/onboarding/bloc/onboarding_event.dart';
import 'package:flock/features/onboarding/bloc/onboarding_state.dart';
import 'package:flock/features/onboarding/widgets/avatar_picker.dart';
import 'package:flock/features/onboarding/widgets/birthday_picker.dart';
import 'package:flock/features/onboarding/widgets/gender_selector.dart';
import 'package:flock/features/onboarding/widgets/name_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Onboarding page for collecting user profile information.
///
/// Collects name, birthday, gender, and optional avatar.
/// Uses progressive disclosure — birthday/gender appear after name is entered.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: _handleStateChange,
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _OnboardingForm(state: state),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, OnboardingState state) {
    if (state.status == OnboardingStatus.success) {
      context.go('/');
    } else if (state.status == OnboardingStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Something went wrong'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// The main form layout.
class _OnboardingForm extends StatelessWidget {
  const _OnboardingForm({required this.state});

  final OnboardingState state;

  bool get _isSubmitting => state.status == OnboardingStatus.submitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisAlignment: .center,
      children: [
        // Header
        Text(
          'Welcome to Flock',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Let's set up your profile",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        const SizedBox(height: 32),

        // Avatar
        AvatarPicker(
          imageBytes: state.avatarBytes,
          initials: state.initials,
          enabled: !_isSubmitting,
          onImageSelected: (bytes, mimeType) {
            context.read<OnboardingBloc>().add(
                  OnboardingAvatarChanged(bytes: bytes, mimeType: mimeType),
                );
          },
        ),
        const SizedBox(height: 32),

        // Name fields
        NameFields(
          enabled: !_isSubmitting,
          onFirstNameChanged: (value) {
            context.read<OnboardingBloc>().add(OnboardingFirstNameChanged(value));
          },
          onLastNameChanged: (value) {
            context.read<OnboardingBloc>().add(OnboardingLastNameChanged(value));
          },
        ),

        // Progressive reveal: Birthday and Gender
        if (state.hasCompleteName) ...[
          const SizedBox(height: 24),
          BirthdayPicker(
            selectedDate: state.birthday,
            enabled: !_isSubmitting,
            onDateSelected: (date) {
              context.read<OnboardingBloc>().add(OnboardingBirthdayChanged(date));
            },
          ),
          const SizedBox(height: 16),
          GenderSelector(
            selectedGender: state.gender,
            enabled: !_isSubmitting,
            onGenderSelected: (gender) {
              context.read<OnboardingBloc>().add(OnboardingGenderChanged(gender));
            },
          ),
        ],

        // Error message
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(message: state.errorMessage!),
        ],

        // Submit button
        const SizedBox(height: 32),
        _SubmitButton(
          canSubmit: state.canSubmit,
          isSubmitting: _isSubmitting,
        ),
      ],
    );
  }
}

/// Error banner shown when submission fails.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: colorScheme.error),
      ),
    );
  }
}

/// Submit button with loading state.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.canSubmit,
    required this.isSubmitting,
  });

  final bool canSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: canSubmit
            ? () => context.read<OnboardingBloc>().add(const OnboardingSubmitted())
            : null,
        child: isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text("Let's go!"),
      ),
    );
  }
}
