import 'dart:async';

import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flock/features/auth/bloc/auth_bloc.dart';
import 'package:flock/features/auth/bloc/forgot_password_bloc.dart';
import 'package:flock/features/auth/bloc/login_bloc.dart';
import 'package:flock/features/auth/bloc/register_bloc.dart';
import 'package:flock/features/auth/bloc/reset_password_bloc.dart';
import 'package:flock/features/auth/pages/check_email_page.dart';
import 'package:flock/features/auth/pages/forgot_password_page.dart';
import 'package:flock/features/auth/pages/login_page.dart';
import 'package:flock/features/auth/pages/register_page.dart';
import 'package:flock/features/auth/pages/reset_password_page.dart';
import 'package:flock/features/auth/pages/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

/// Creates the app router with auth guards.
GoRouter createRouter({
  required AuthBloc authBloc,
  required BetterAuthClient authClient,
}) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthRoute = _isAuthRoute(state.matchedLocation);
      final isTokenRoute = _isTokenRoute(state.matchedLocation);

      // Token routes (password reset, email verify) are always accessible
      if (isTokenRoute) return null;

      // Unauthenticated users must go to auth pages
      if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }

      // Authenticated users shouldn't see auth pages
      if (authState.status == AuthStatus.authenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => BlocProvider(
          create: (_) => LoginBloc(authClient: authClient),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => BlocProvider(
          create: (_) => RegisterBloc(authClient: authClient),
          child: const RegisterPage(),
        ),
      ),
      GoRoute(
        path: '/check-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return CheckEmailPage(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => BlocProvider(
          create: (_) => ForgotPasswordBloc(authClient: authClient),
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return BlocProvider(
            create: (_) => ResetPasswordBloc(
              authClient: authClient,
              token: token,
            ),
            child: ResetPasswordPage(token: token),
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return VerifyEmailPage(
            token: token,
            authClient: authClient,
          );
        },
      ),
    ],
  );
}

bool _isAuthRoute(String location) {
  return ['/login', '/register', '/forgot-password', '/check-email']
      .any((p) => location.startsWith(p));
}

bool _isTokenRoute(String location) {
  return ['/reset-password', '/verify-email']
      .any((p) => location.startsWith(p));
}

/// Temporary home page placeholder.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flock'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, state) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleCheck,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome, ${state.user?.name ?? state.user?.email ?? 'User'}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
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

/// Converts a stream to a Listenable for GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
