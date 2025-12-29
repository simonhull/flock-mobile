import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flock/features/onboarding/domain/entities/gender.dart';

/// Events for the onboarding bloc.
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// User updated the first name field.
final class OnboardingFirstNameChanged extends OnboardingEvent {
  const OnboardingFirstNameChanged(this.firstName);

  final String firstName;

  @override
  List<Object?> get props => [firstName];
}

/// User updated the last name field.
final class OnboardingLastNameChanged extends OnboardingEvent {
  const OnboardingLastNameChanged(this.lastName);

  final String lastName;

  @override
  List<Object?> get props => [lastName];
}

/// User selected a birthday.
final class OnboardingBirthdayChanged extends OnboardingEvent {
  const OnboardingBirthdayChanged(this.birthday);

  final DateTime birthday;

  @override
  List<Object?> get props => [birthday];
}

/// User selected a gender.
final class OnboardingGenderChanged extends OnboardingEvent {
  const OnboardingGenderChanged(this.gender);

  final Gender gender;

  @override
  List<Object?> get props => [gender];
}

/// User selected an avatar image.
final class OnboardingAvatarChanged extends OnboardingEvent {
  const OnboardingAvatarChanged({
    required this.bytes,
    required this.mimeType,
  });

  /// The cropped image bytes.
  final Uint8List bytes;

  /// The MIME type of the image (e.g., 'image/jpeg').
  final String mimeType;

  @override
  List<Object?> get props => [bytes, mimeType];
}

/// User submitted the onboarding form.
final class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted();
}
