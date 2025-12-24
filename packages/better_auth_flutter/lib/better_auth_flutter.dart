/// BetterAuth client for Flutter.
///
/// A type-safe, functional Flutter client for BetterAuth authentication.
///
/// ## Usage
///
/// ```dart
/// import 'package:better_auth_flutter/better_auth_flutter.dart';
///
/// final client = BetterAuthClientImpl(
///   baseUrl: 'https://your-api.com',
///   storage: SecureStorageImpl(),
/// );
///
/// // Initialize from stored session
/// await client.initialize().run();
///
/// // Sign in
/// final result = await client.signIn(
///   email: 'user@example.com',
///   password: 'password',
/// ).run();
///
/// switch (result) {
///   case Right(:final value):
///     print('Signed in as ${value.user.email}');
///   case Left(:final value):
///     print('Error: ${value.message}');
/// }
/// ```
library;

// Client
export 'src/client/better_auth_client.dart';
export 'src/client/better_auth_client_impl.dart';

// Models
export 'src/models/auth_error.dart';
export 'src/models/auth_state.dart';
export 'src/models/session.dart';
export 'src/models/user.dart';

// Storage
export 'src/storage/auth_storage.dart';
export 'src/storage/memory_storage_impl.dart';
export 'src/storage/secure_storage_impl.dart';
