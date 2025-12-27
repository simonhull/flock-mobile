import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';

/// Email verification page that auto-verifies on load.
///
/// This page is accessed via deep link with a token parameter.
/// It automatically attempts verification and shows the result.
final class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    required this.token,
    required this.authClient,
    super.key,
  });

  final String token;
  final BetterAuthClient authClient;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

final class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late Future<Either<AuthError, Unit>> _verificationFuture;

  @override
  void initState() {
    super.initState();
    _verificationFuture = widget.authClient.verifyEmail(token: widget.token).run();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Either<AuthError, Unit>>(
          future: _verificationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingView();
            }

            final result = snapshot.data;
            if (result == null) {
              return const _ErrorView(message: 'Verification failed');
            }

            return switch (result) {
              Right() => const _SuccessView(),
              Left(:final value) => _ErrorView(message: value.message),
            };
          },
        ),
      ),
    );
  }
}

final class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Verifying your email...'),
        ],
      ),
    );
  }
}

final class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Email verified!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your email has been successfully verified.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Continue to login'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Verification failed',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
