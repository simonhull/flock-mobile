import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flock/core/di/injection.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependencies
  await configureDependencies();

  runApp(const FlockApp());
}

class FlockApp extends StatelessWidget {
  const FlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthStatusPage(),
    );
  }
}

/// Temporary page to show auth client is working.
class AuthStatusPage extends StatelessWidget {
  const AuthStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authClient = getIt<BetterAuthClient>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<AuthState>(
        stream: authClient.authStateChanges,
        builder: (context, snapshot) {
          final state = snapshot.data ?? authClient.currentState;

          return Center(
            child: Column(
              mainAxisAlignment: .center,
              children: [
                Icon(
                  switch (state) {
                    Authenticated() => Icons.check_circle,
                    Unauthenticated() => Icons.person_off,
                    AuthLoading() => Icons.hourglass_empty,
                    AuthInitial() => Icons.help_outline,
                  },
                  size: 64,
                  color: switch (state) {
                    Authenticated() => Colors.green,
                    Unauthenticated() => Colors.orange,
                    AuthLoading() => Colors.blue,
                    AuthInitial() => Colors.grey,
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  switch (state) {
                    Authenticated(:final user) => 'Signed in as ${user.email}',
                    Unauthenticated() => 'Not signed in',
                    AuthLoading() => 'Loading...',
                    AuthInitial() => 'Initializing...',
                  },
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Auth client is working!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
