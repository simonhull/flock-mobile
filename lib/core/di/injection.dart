import 'dart:io' show Platform;

import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:get_it/get_it.dart';

/// Global service locator.
final getIt = GetIt.instance;

/// API base URL from environment or platform-appropriate default.
///
/// Override with `--dart-define=API_URL=http://your-server:port`.
///
/// Platform defaults (port 5173 for SvelteKit dev server):
/// - Android emulator: 10.0.2.2 (maps to host machine's localhost)
/// - iOS/macOS/Linux/Windows: localhost
String get _apiUrl {
  const override = String.fromEnvironment('API_URL');
  if (override.isNotEmpty) return override;

  // Android emulator needs special IP to reach host machine
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  return 'http://$host:5173';
}

/// Configure all dependencies.
Future<void> configureDependencies() async {
  getIt
    // Storage
    ..registerLazySingleton<AuthStorage>(SecureStorageImpl.new)
    // Auth client
    ..registerLazySingleton<BetterAuthClient>(
      () => BetterAuthClientImpl(
        baseUrl: _apiUrl,
        storage: getIt<AuthStorage>(),
      ),
    );

  // Initialize auth (restore session from storage)
  await getIt<BetterAuthClient>().initialize().run();
}
