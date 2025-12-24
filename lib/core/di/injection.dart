import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:get_it/get_it.dart';

/// Global service locator.
final getIt = GetIt.instance;

/// API base URL from environment.
const _apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8788', // Android emulator localhost
);

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
