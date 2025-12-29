import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flock/features/onboarding/domain/entities/gender.dart';

/// Parameters for creating a new profile.
///
/// Immutable value object containing all required profile data.
final class CreateProfileParams extends Equatable {
  const CreateProfileParams({
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.gender,
    this.avatarBytes,
    this.avatarMimeType,
  });

  final String firstName;
  final String lastName;
  final DateTime birthday;
  final Gender gender;

  /// Optional avatar image bytes.
  final Uint8List? avatarBytes;

  /// MIME type of avatar (e.g., 'image/jpeg').
  final String? avatarMimeType;

  /// Whether an avatar image is included.
  bool get hasAvatar => avatarBytes != null && avatarMimeType != null;

  /// Birthday formatted as ISO date (YYYY-MM-DD).
  String get birthdayIso {
    final y = birthday.year.toString().padLeft(4, '0');
    final m = birthday.month.toString().padLeft(2, '0');
    final d = birthday.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        birthday,
        gender,
        avatarBytes,
        avatarMimeType,
      ];
}
