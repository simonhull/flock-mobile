import 'package:better_auth_flutter/src/client/error_mapper.dart';
import 'package:better_auth_flutter/src/client/plugin_context.dart';
import 'package:better_auth_flutter/src/models/auth_error.dart';
import 'package:better_auth_flutter/src/models/auth_state.dart';
import 'package:better_auth_flutter/src/models/session.dart';
import 'package:better_auth_flutter/src/models/user.dart';
import 'package:better_auth_flutter/src/sso/sso_browser_handler.dart';
import 'package:better_auth_flutter/src/sso/sso_models.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Enterprise SSO (OIDC/SAML/OAuth2) authentication capability.
///
/// Enables authentication through corporate identity providers like
/// Okta, Azure AD, Google Workspace, and custom SAML/OIDC providers.
///
/// Usage:
/// ```dart
/// final browserHandler = FlutterWebAuthHandler();
///
/// // Check if SSO is available for email domain
/// final provider = await client.sso.checkDomain(
///   email: 'user@company.com',
/// ).run();
///
/// if (provider != null) {
///   // Sign in with SSO
///   await client.sso.signIn(
///     email: 'user@company.com',
///     browserHandler: browserHandler,
///   ).run();
/// }
/// ```
final class SSO {
  SSO(this._ctx);

  final PluginContext _ctx;

  /// Sign in with SSO.
  ///
  /// Provide either [email] for domain-based provider lookup or [providerId]
  /// for explicit provider selection.
  ///
  /// The [browserHandler] is called to open the IdP login page and capture
  /// the callback URL after authentication.
  ///
  /// Returns [Authenticated] on success.
  /// Throws [SSOProviderNotFound] if no provider is configured for the domain.
  /// Throws [SSOProviderDisabled] if the provider is disabled.
  /// Throws [SSOStateMismatch] if state validation fails (CSRF protection).
  /// Throws [SSOCancelled] if the user cancels the flow.
  TaskEither<AuthError, Authenticated> signIn({
    required SSOBrowserHandler browserHandler,
    String? email,
    String? providerId,
    String? callbackUrl,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (email == null && providerId == null) {
          throw const UnknownError(
            message: 'Either email or providerId is required',
            code: 'INVALID_PARAMS',
          );
        }

        _ctx.emitState(const AuthLoading());

        // 1. Get authorization URL from server
        final initResponse = await _ctx.dio.post<dynamic>(
          '/api/auth/sso/sign-in',
          data: <String, dynamic>{
            if (email != null) 'email': email,
            if (providerId != null) 'providerId': providerId,
            if (callbackUrl != null) 'callbackURL': callbackUrl,
          },
        );

        if (initResponse.statusCode != 200) {
          throw _mapResponse(initResponse);
        }

        final authResponse = SSOAuthorizationResponse.fromJson(
          initResponse.data as Map<String, dynamic>,
        );

        // 2. Open browser and wait for callback
        final callbackUri = await browserHandler.openAndWaitForCallback(
          authorizationUrl: authResponse.authorizationUrl,
          callbackUrl: authResponse.callbackUrl,
        );

        // 3. Verify state parameter (CSRF protection)
        final returnedState = callbackUri.queryParameters['state'];
        if (returnedState != authResponse.state) {
          throw const SSOStateMismatch();
        }

        // 4. Handle callback with server
        final tokenResponse = await _ctx.dio.get<dynamic>(
          '/api/auth/sso/callback/${authResponse.providerId}',
          queryParameters: callbackUri.queryParameters,
        );

        if (tokenResponse.statusCode != 200) {
          throw _mapResponse(tokenResponse);
        }

        // 5. Extract user and session/token
        final data = tokenResponse.data as Map<String, dynamic>;
        final user = User.fromJson(data['user'] as Map<String, dynamic>);

        // BetterAuth may return either:
        // - 'session' object (legacy format)
        // - 'token' at top level (bearer plugin format)
        final Session session;
        final sessionData = data['session'] as Map<String, dynamic>?;
        if (sessionData != null) {
          session = Session.fromJson(sessionData);
        } else {
          // Extract token from top level or response header
          final token = data['token'] as String? ??
              tokenResponse.headers.value('set-auth-token');
          if (token == null) {
            throw const UnknownError(
              message: 'No session or token in response',
              code: 'INVALID_RESPONSE',
            );
          }
          session = Session(
            id: token,
            userId: user.id,
            token: token,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          );
        }

        await _ctx.storage.saveUser(user).run();
        await _ctx.storage.saveSession(session).run();

        final state = Authenticated(user: user, session: session);
        _ctx.emitState(state);

        return state;
      },
      (error, stackTrace) {
        _ctx.emitState(const Unauthenticated());
        return _mapError(error, stackTrace);
      },
    );
  }

  /// Check if SSO is available for an email domain.
  ///
  /// Returns the provider info if configured, null otherwise.
  /// This is useful for determining whether to show SSO options
  /// during sign-in.
  TaskEither<AuthError, SSOProvider?> checkDomain({
    required String email,
  }) {
    return TaskEither.tryCatch(
      () async {
        final domain = email.split('@').last;

        final response = await _ctx.dio.get<dynamic>(
          '/api/auth/sso/providers',
          queryParameters: {'domain': domain},
        );

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        final data = response.data as Map<String, dynamic>;
        final providers = data['providers'] as List<dynamic>?;

        if (providers == null || providers.isEmpty) {
          return null;
        }

        return SSOProvider.fromJson(
          providers.first as Map<String, dynamic>,
        );
      },
      _mapError,
    );
  }

  /// List all SSO providers.
  ///
  /// Returns all configured providers. This may be restricted to
  /// admin users depending on server configuration.
  TaskEither<AuthError, List<SSOProvider>> listProviders() {
    return TaskEither.tryCatch(
      () async {
        final response = await _ctx.dio.get<dynamic>('/api/auth/sso/providers');

        if (response.statusCode != 200) {
          throw _mapResponse(response);
        }

        final data = response.data as Map<String, dynamic>;
        final providers = (data['providers'] as List<dynamic>)
            .map((p) => SSOProvider.fromJson(p as Map<String, dynamic>))
            .toList();

        return providers;
      },
      _mapError,
    );
  }

  // === Error Handling ===

  /// Map response to SSO-specific errors, falling back to standard mapping.
  AuthError _mapResponse(Response<dynamic> response) {
    return ErrorMapper.mapResponse(
      response,
      onCode: (code, message) => switch (code) {
        'SSO_PROVIDER_NOT_FOUND' => const SSOProviderNotFound(),
        'SSO_PROVIDER_DISABLED' => const SSOProviderDisabled(),
        'SSO_STATE_MISMATCH' => const SSOStateMismatch(),
        'SSO_CALLBACK_ERROR' => SSOCallbackError(
          message: message ?? 'Callback error',
        ),
        _ => null, // Fall back to standard mapping
      },
    );
  }

  /// Map any error to AuthError, with SSO-specific handling.
  AuthError _mapError(Object error, StackTrace stackTrace) {
    // Handle SSO-specific: browser cancellation
    if (error is! AuthError && error is! DioException) {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('cancel')) {
        return const SSOCancelled();
      }
    }

    // Delegate to shared mapper
    return ErrorMapper.map(error, stackTrace);
  }
}
