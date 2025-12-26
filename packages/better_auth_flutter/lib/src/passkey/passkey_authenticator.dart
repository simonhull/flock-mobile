import 'package:better_auth_flutter/src/passkey/passkey_models.dart';

/// Interface for platform-specific WebAuthn operations.
///
/// Users implement this using packages like:
/// - `passkeys` (cross-platform)
/// - `local_auth` + custom platform channels
///
/// Example implementation using the `passkeys` package:
/// ```dart
/// final class FlutterPasskeyAuthenticator implements PasskeyAuthenticator {
///   final _passkeys = Passkeys();
///
///   @override
///   Future<bool> isSupported() => _passkeys.canAuthenticate();
///
///   @override
///   Future<bool> isAvailable() => _passkeys.canAuthenticate();
///
///   @override
///   Future<RegistrationResponse> createCredential(
///     RegistrationOptions options,
///   ) async {
///     final result = await _passkeys.register(
///       relyingPartyId: options.relyingParty.id,
///       relyingPartyName: options.relyingParty.name,
///       userId: options.user.id,
///       userName: options.user.name,
///       userDisplayName: options.user.displayName,
///       challenge: options.challenge,
///     );
///
///     return RegistrationResponse(
///       id: result.id,
///       rawId: result.rawId,
///       type: 'public-key',
///       response: AttestationResponse(
///         clientDataJSON: result.clientDataJSON,
///         attestationObject: result.attestationObject,
///         transports: result.transports,
///       ),
///     );
///   }
///
///   @override
///   Future<AuthenticationResponse> getAssertion(
///     AuthenticationOptions options,
///   ) async {
///     final result = await _passkeys.authenticate(
///       relyingPartyId: options.rpId,
///       challenge: options.challenge,
///     );
///
///     return AuthenticationResponse(
///       id: result.id,
///       rawId: result.rawId,
///       type: 'public-key',
///       response: AssertionResponse(
///         clientDataJSON: result.clientDataJSON,
///         authenticatorData: result.authenticatorData,
///         signature: result.signature,
///         userHandle: result.userHandle,
///       ),
///     );
///   }
/// }
/// ```
abstract interface class PasskeyAuthenticator {
  /// Check if passkeys are supported on this device.
  ///
  /// Returns true if the device hardware supports WebAuthn.
  Future<bool> isSupported();

  /// Check if passkeys are available (supported and configured).
  ///
  /// Returns true if passkeys are supported AND the user has
  /// set up biometrics or a device PIN.
  Future<bool> isAvailable();

  /// Create a new credential (registration).
  ///
  /// [options] contains the challenge and relying party info from server.
  /// Returns the attestation to send to server.
  ///
  /// Throws if the user cancels or the operation fails.
  Future<RegistrationResponse> createCredential(RegistrationOptions options);

  /// Get an assertion for existing credential (authentication).
  ///
  /// [options] contains the challenge and allowed credentials from server.
  /// Returns the assertion to send to server.
  ///
  /// Throws if the user cancels or no matching credential exists.
  Future<AuthenticationResponse> getAssertion(AuthenticationOptions options);
}
