/// Common test fixtures for Better Auth tests.
abstract final class AuthFixtures {
  /// Default base URL for tests.
  static const baseUrl = 'https://api.example.com';

  /// Creates a mock auth response with user and session.
  static Map<String, dynamic> authResponse({
    String userId = 'user-123',
    String email = 'test@example.com',
    String? name = 'Test User',
    bool emailVerified = true,
    String sessionId = 'session-123',
    String token = 'token-abc',
    Duration expiresIn = const Duration(days: 7),
    bool isAnonymous = false,
  }) {
    return {
      'user': user(
        id: userId,
        email: email,
        name: name,
        emailVerified: emailVerified,
        isAnonymous: isAnonymous,
      ),
      'session': session(
        id: sessionId,
        token: token,
        userId: userId,
        expiresIn: expiresIn,
      ),
    };
  }

  /// Creates a mock user response.
  static Map<String, dynamic> user({
    String id = 'user-123',
    String email = 'test@example.com',
    String? name = 'Test User',
    bool emailVerified = true,
    bool isAnonymous = false,
  }) {
    return {
      'id': id,
      'email': email,
      'name': name,
      'emailVerified': emailVerified,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
      if (isAnonymous) 'isAnonymous': true,
    };
  }

  /// Creates a mock session response.
  static Map<String, dynamic> session({
    String id = 'session-123',
    String token = 'token-abc',
    String userId = 'user-123',
    Duration expiresIn = const Duration(days: 7),
  }) {
    return {
      'id': id,
      'token': token,
      'userId': userId,
      'expiresAt': DateTime.now().add(expiresIn).toIso8601String(),
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-01-01T00:00:00.000Z',
    };
  }

  /// Creates an anonymous auth response.
  static Map<String, dynamic> anonymousAuthResponse({
    String userId = 'anon-user-123',
    String sessionId = 'session-456',
    String token = 'anon-token-abc',
  }) {
    return authResponse(
      userId: userId,
      email: '',
      name: null,
      emailVerified: false,
      sessionId: sessionId,
      token: token,
      expiresIn: const Duration(days: 30),
      isAnonymous: true,
    );
  }

  /// Creates a two-factor setup response.
  static Map<String, dynamic> twoFactorSetup({
    String totpUri = 'otpauth://totp/MyApp:user@example.com?secret=ABC123',
    String secret = 'ABC123',
    List<String> backupCodes = const ['code1', 'code2', 'code3'],
  }) {
    return {
      'totpURI': totpUri,
      'secret': secret,
      'backupCodes': backupCodes,
    };
  }

  /// Creates a magic link sent response.
  static Map<String, dynamic> magicLinkSent({
    String email = 'user@example.com',
    DateTime? expiresAt,
  }) {
    return {
      'email': email,
      'expiresAt':
          (expiresAt ?? DateTime.now().add(const Duration(hours: 1)))
              .toIso8601String(),
    };
  }

  /// Creates an error response.
  static Map<String, dynamic> error({
    required String message,
    String? code,
  }) {
    return {
      'message': message,
      if (code != null) 'code': code,
    };
  }

  /// Creates a passkey registration options response.
  static Map<String, dynamic> passkeyRegistrationOptions({
    String rpId = 'example.com',
    String rpName = 'Example App',
    String challenge = 'base64-challenge',
    String userId = 'user-123',
    String userName = 'test@example.com',
  }) {
    return {
      'rp': {'id': rpId, 'name': rpName},
      'challenge': challenge,
      'user': {
        'id': userId,
        'name': userName,
        'displayName': userName,
      },
      'pubKeyCredParams': [
        {'type': 'public-key', 'alg': -7},
        {'type': 'public-key', 'alg': -257},
      ],
      'timeout': 60000,
      'authenticatorSelection': {
        'authenticatorAttachment': 'platform',
        'residentKey': 'required',
        'userVerification': 'required',
      },
    };
  }

  /// Creates a passkey authentication options response.
  static Map<String, dynamic> passkeyAuthenticationOptions({
    String rpId = 'example.com',
    String challenge = 'auth-challenge',
  }) {
    return {
      'rpId': rpId,
      'challenge': challenge,
      'timeout': 60000,
      'userVerification': 'required',
      'allowCredentials': <Map<String, dynamic>>[],
    };
  }

  /// Creates an SSO authorization response.
  static Map<String, dynamic> ssoAuthorization({
    String authorizationUrl =
        'https://sso.example.com/auth?client_id=abc&state=xyz',
    String state = 'xyz',
  }) {
    return {
      'url': authorizationUrl,
      'state': state,
    };
  }
}
