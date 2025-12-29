import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flock/features/onboarding/domain/entities/gender.dart';
import 'package:flock/features/onboarding/domain/entities/profile.dart';

/// Status of the onboarding submission.
enum OnboardingStatus {
  initial,
  submitting,
  success,
  failure,
}

/// State for the onboarding bloc.
final class OnboardingState extends Equatable {
  const OnboardingState({
    this.firstName = '',
    this.lastName = '',
    this.birthday,
    this.gender,
    this.avatarBytes,
    this.avatarMimeType,
    this.status = OnboardingStatus.initial,
    this.errorMessage,
    this.profile,
  });

  /// User's first name.
  final String firstName;

  /// User's last name.
  final String lastName;

  /// User's birthday.
  final DateTime? birthday;

  /// User's selected gender.
  final Gender? gender;

  /// Avatar image bytes (after cropping).
  final Uint8List? avatarBytes;

  /// Avatar MIME type.
  final String? avatarMimeType;

  /// Current submission status.
  final OnboardingStatus status;

  /// Error message if submission failed.
  final String? errorMessage;

  /// Created profile on success.
  final Profile? profile;

  /// Whether name fields are complete (enables extended fields).
  bool get hasCompleteName =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  /// Whether all required fields are filled and form can be submitted.
  bool get canSubmit =>
      hasCompleteName &&
      birthday != null &&
      gender != null &&
      status != OnboardingStatus.submitting;

  /// User's initials for avatar fallback.
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();

    if (first.isEmpty && last.isEmpty) return '?';

    final firstInitial = first.isNotEmpty ? first[0].toUpperCase() : '';
    final lastInitial = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  /// Create a copy with updated fields.
  OnboardingState copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthday,
    Gender? gender,
    Uint8List? avatarBytes,
    String? avatarMimeType,
    OnboardingStatus? status,
    String? errorMessage,
    Profile? profile,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      avatarMimeType: avatarMimeType ?? this.avatarMimeType,
      status: status ?? this.status,
      errorMessage: errorMessage,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        birthday,
        gender,
        avatarBytes,
        avatarMimeType,
        status,
        errorMessage,
        profile,
      ];
}
