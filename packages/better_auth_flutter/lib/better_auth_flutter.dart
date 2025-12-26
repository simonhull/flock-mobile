/// BetterAuth client for Flutter.
///
/// A type-safe, functional Flutter client for BetterAuth authentication.
///
/// ## Basic Usage
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
/// // Sign in with email/password
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
///
/// ## Social Authentication
///
/// To add social sign-in, implement `OAuthProvider` for your chosen provider.
/// Import the extension and call `signInWithProvider`:
///
/// ```dart
/// // 1. Add google_sign_in to your pubspec.yaml
/// // 2. Create your provider:
///
/// import 'package:google_sign_in/google_sign_in.dart';
///
/// final class GoogleOAuthProvider implements OAuthProvider {
///   GoogleOAuthProvider({required this.clientId});
///
///   final String clientId;
///
///   @override
///   String get providerId => 'google';
///
///   @override
///   Future<OAuthCredential> authenticate() async {
///     final googleSignIn = GoogleSignIn(
///       clientId: clientId,
///       scopes: ['email', 'profile'],
///     );
///
///     final account = await googleSignIn.signIn();
///     if (account == null) throw const OAuthCancelled();
///
///     final auth = await account.authentication;
///     if (auth.idToken == null) {
///       throw const OAuthProviderError(
///         provider: 'Google',
///         details: 'No ID token returned',
///       );
///     }
///
///     return OAuthCredential(
///       idToken: auth.idToken!,
///       accessToken: auth.accessToken,
///     );
///   }
/// }
///
/// // 3. Use it:
/// final provider = GoogleOAuthProvider(clientId: 'your-client-id');
/// final result = await client.signInWithProvider(provider).run();
/// ```
///
/// For Apple Sign In, use the `sign_in_with_apple` package and include
/// the nonce in the credential for security.
library;

// Client
export 'src/client/better_auth_client.dart';
export 'src/client/better_auth_client_impl.dart';
export 'src/client/session_validation_extension.dart';
export 'src/client/social_auth_extension.dart';

// Connectivity
export 'src/connectivity/connectivity_monitor.dart';

// Magic Link
export 'src/magic_link/magic_link.dart';
export 'src/magic_link/magic_link_extension.dart';

// Models
export 'src/models/auth_error.dart';
export 'src/models/auth_state.dart';
export 'src/models/magic_link_sent.dart';
export 'src/models/session.dart';
export 'src/models/two_factor_setup.dart';
export 'src/models/user.dart';

// Queue
export 'src/queue/offline_queue.dart';
export 'src/queue/queued_operation.dart';

// Social
export 'src/social/oauth_credential.dart';
export 'src/social/oauth_provider.dart';

// Storage
export 'src/storage/auth_storage.dart';
export 'src/storage/cookie_storage.dart';
export 'src/storage/memory_storage_impl.dart';
export 'src/storage/secure_storage_impl.dart';

// Two-Factor
export 'src/two_factor/two_factor.dart';
export 'src/two_factor/two_factor_extension.dart';
