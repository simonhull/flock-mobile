import 'dart:io' show Platform;

import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:flock/core/network/api_client.dart';
import 'package:flock/core/network/auth_interceptor.dart';
import 'package:flock/features/onboarding/data/datasources/profile_remote_datasource.dart';
import 'package:flock/features/onboarding/data/repositories/profile_repository_impl.dart';
import 'package:flock/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:flock/features/onboarding/domain/usecases/create_profile.dart';
import 'package:get_it/get_it.dart';

/// Global service locator.
final GetIt getIt = GetIt.instance;

/// API base URL from environment or platform-appropriate default.
///
/// Override with `--dart-define=API_URL=http://your-server:port`.
///
/// Platform defaults (port 5173 for SvelteKit dev server):
/// - Android emulator: 10.0.2.2 (maps to host machine's localhost)
/// - iOS/macOS/Linux/Windows: localhost
String get apiUrl {
  const override = String.fromEnvironment('API_URL');
  if (override.isNotEmpty) return override;

  // Android emulator needs special IP to reach host machine
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  return 'http://$host:5173';
}

/// Configure all dependencies.
Future<void> configureDependencies() async {
  // Storage
  getIt.registerLazySingleton<AuthStorage>(SecureStorageImpl.new);

  // Auth client
  getIt.registerLazySingleton<BetterAuthClient>(
    () => BetterAuthClientImpl(
      baseUrl: apiUrl,
      storage: getIt<AuthStorage>(),
    ),
  );

  // Auth interceptor
  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(getIt<BetterAuthClient>()),
  );

  // API client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClientImpl(
      baseUrl: '$apiUrl/api/v1',
      authInterceptor: getIt<AuthInterceptor>(),
    ),
  );

  // Data sources
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt<ApiClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(getIt<ProfileRemoteDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton<CreateProfile>(
    () => CreateProfile(getIt<ProfileRepository>()),
  );

  // Initialize auth (restore session from storage)
  await getIt<BetterAuthClient>().initialize().run();
}
