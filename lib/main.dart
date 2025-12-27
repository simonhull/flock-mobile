import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flock/core/di/injection.dart';
import 'package:flock/core/router/router.dart';
import 'package:flock/core/theme/app_theme.dart';
import 'package:flock/features/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependencies
  await configureDependencies();

  runApp(const FlockApp());
}

class FlockApp extends StatefulWidget {
  const FlockApp({super.key});

  @override
  State<FlockApp> createState() => _FlockAppState();
}

class _FlockAppState extends State<FlockApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authClient = getIt<BetterAuthClient>();
    _authBloc = AuthBloc(authClient: authClient);
    _router = createRouter(authBloc: _authBloc, authClient: authClient);

    // Trigger initial auth check
    _authBloc.add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'Flock',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}
