import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Page shown after registration to prompt email verification.
final class CheckEmailPage extends StatelessWidget {
  const CheckEmailPage({
    required this.email,
    super.key,
  });

  /// The email address where verification was sent.
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FaIcon(
                FontAwesomeIcons.envelope,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Check your email',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Click the link in the email to verify your account.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to sign in'),
              ),
              const SizedBox(height: 16),
              Text(
                "Didn't receive the email? Check your spam folder.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
