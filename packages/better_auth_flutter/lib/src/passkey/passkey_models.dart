import 'package:flutter/foundation.dart' show immutable;

// === Registration ===

/// Options for passkey registration from server.
@immutable
final class RegistrationOptions {
  const RegistrationOptions({
    required this.challenge,
    required this.relyingParty,
    required this.user,
    required this.pubKeyCredParams,
    this.timeout = const Duration(minutes: 5),
    this.attestation,
    this.authenticatorSelection,
  });

  factory RegistrationOptions.fromJson(Map<String, dynamic> json) {
    final rp = json['rp'] as Map<String, dynamic>;
    final user = json['user'] as Map<String, dynamic>;
    final params = json['pubKeyCredParams'] as List<dynamic>? ?? [];

    return RegistrationOptions(
      challenge: json['challenge'] as String,
      relyingParty: RelyingParty(
        id: rp['id'] as String,
        name: rp['name'] as String,
      ),
      user: WebAuthnUserInfo(
        id: user['id'] as String,
        name: user['name'] as String,
        displayName: user['displayName'] as String,
      ),
      pubKeyCredParams: params
          .map(
            (p) => PublicKeyCredentialParam(
              type: (p as Map<String, dynamic>)['type'] as String,
              alg: p['alg'] as int,
            ),
          )
          .toList(),
      timeout: Duration(milliseconds: json['timeout'] as int? ?? 300000),
      attestation: json['attestation'] as String?,
      authenticatorSelection: json['authenticatorSelection'] != null
          ? AuthenticatorSelection.fromJson(
              json['authenticatorSelection'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String challenge;
  final RelyingParty relyingParty;
  final WebAuthnUserInfo user;
  final List<PublicKeyCredentialParam> pubKeyCredParams;
  final Duration timeout;
  final String? attestation;
  final AuthenticatorSelection? authenticatorSelection;
}

/// Relying party information (the server).
@immutable
final class RelyingParty {
  const RelyingParty({required this.id, required this.name});

  final String id;
  final String name;
}

/// User information for WebAuthn.
@immutable
final class WebAuthnUserInfo {
  const WebAuthnUserInfo({
    required this.id,
    required this.name,
    required this.displayName,
  });

  final String id;
  final String name;
  final String displayName;
}

/// Public key credential algorithm parameter.
@immutable
final class PublicKeyCredentialParam {
  const PublicKeyCredentialParam({required this.type, required this.alg});

  final String type;

  /// COSE algorithm identifier (e.g., -7 for ES256, -257 for RS256).
  final int alg;
}

/// Authenticator selection criteria.
@immutable
final class AuthenticatorSelection {
  const AuthenticatorSelection({
    this.authenticatorAttachment,
    this.requireResidentKey,
    this.residentKey,
    this.userVerification,
  });

  factory AuthenticatorSelection.fromJson(Map<String, dynamic> json) {
    return AuthenticatorSelection(
      authenticatorAttachment: json['authenticatorAttachment'] as String?,
      requireResidentKey: json['requireResidentKey'] as bool?,
      residentKey: json['residentKey'] as String?,
      userVerification: json['userVerification'] as String?,
    );
  }

  /// 'platform' | 'cross-platform'
  final String? authenticatorAttachment;
  final bool? requireResidentKey;

  /// 'discouraged' | 'preferred' | 'required'
  final String? residentKey;

  /// 'required' | 'preferred' | 'discouraged'
  final String? userVerification;
}

/// Response from authenticator after creating credential.
@immutable
final class RegistrationResponse {
  const RegistrationResponse({
    required this.id,
    required this.rawId,
    required this.type,
    required this.response,
    this.authenticatorAttachment,
  });

  final String id;
  final String rawId;
  final String type;
  final AttestationResponse response;
  final String? authenticatorAttachment;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawId': rawId,
        'type': type,
        'response': response.toJson(),
        if (authenticatorAttachment != null)
          'authenticatorAttachment': authenticatorAttachment,
      };
}

/// Attestation response containing the credential.
@immutable
final class AttestationResponse {
  const AttestationResponse({
    required this.clientDataJSON,
    required this.attestationObject,
    this.transports,
  });

  final String clientDataJSON;
  final String attestationObject;
  final List<String>? transports;

  Map<String, dynamic> toJson() => {
        'clientDataJSON': clientDataJSON,
        'attestationObject': attestationObject,
        if (transports != null) 'transports': transports,
      };
}

// === Authentication ===

/// Options for passkey authentication from server.
@immutable
final class AuthenticationOptions {
  const AuthenticationOptions({
    required this.challenge,
    required this.rpId,
    this.timeout = const Duration(minutes: 5),
    this.allowCredentials = const [],
    this.userVerification,
  });

  factory AuthenticationOptions.fromJson(Map<String, dynamic> json) {
    final creds = json['allowCredentials'] as List<dynamic>? ?? [];

    return AuthenticationOptions(
      challenge: json['challenge'] as String,
      rpId: json['rpId'] as String,
      timeout: Duration(milliseconds: json['timeout'] as int? ?? 300000),
      allowCredentials: creds
          .map(
            (c) => AllowedCredential.fromJson(c as Map<String, dynamic>),
          )
          .toList(),
      userVerification: json['userVerification'] as String?,
    );
  }

  final String challenge;
  final String rpId;
  final Duration timeout;
  final List<AllowedCredential> allowCredentials;
  final String? userVerification;
}

/// Credential allowed for authentication.
@immutable
final class AllowedCredential {
  const AllowedCredential({
    required this.id,
    required this.type,
    this.transports,
  });

  factory AllowedCredential.fromJson(Map<String, dynamic> json) {
    return AllowedCredential(
      id: json['id'] as String,
      type: json['type'] as String,
      transports: (json['transports'] as List<dynamic>?)?.cast<String>(),
    );
  }

  final String id;
  final String type;
  final List<String>? transports;
}

/// Response from authenticator after signing challenge.
@immutable
final class AuthenticationResponse {
  const AuthenticationResponse({
    required this.id,
    required this.rawId,
    required this.type,
    required this.response,
    this.authenticatorAttachment,
  });

  final String id;
  final String rawId;
  final String type;
  final AssertionResponse response;
  final String? authenticatorAttachment;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawId': rawId,
        'type': type,
        'response': response.toJson(),
        if (authenticatorAttachment != null)
          'authenticatorAttachment': authenticatorAttachment,
      };
}

/// Assertion response containing the signature.
@immutable
final class AssertionResponse {
  const AssertionResponse({
    required this.clientDataJSON,
    required this.authenticatorData,
    required this.signature,
    this.userHandle,
  });

  final String clientDataJSON;
  final String authenticatorData;
  final String signature;
  final String? userHandle;

  Map<String, dynamic> toJson() => {
        'clientDataJSON': clientDataJSON,
        'authenticatorData': authenticatorData,
        'signature': signature,
        if (userHandle != null) 'userHandle': userHandle,
      };
}

// === Stored Passkey Info ===

/// Information about a registered passkey.
@immutable
final class PasskeyInfo {
  const PasskeyInfo({
    required this.id,
    required this.credentialId,
    required this.createdAt,
    this.name,
    this.lastUsedAt,
    this.deviceType,
  });

  factory PasskeyInfo.fromJson(Map<String, dynamic> json) {
    return PasskeyInfo(
      id: json['id'] as String,
      credentialId: json['credentialId'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      deviceType: json['deviceType'] as String?,
    );
  }

  final String id;
  final String credentialId;
  final String? name;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final String? deviceType;
}
