import 'package:equatable/equatable.dart';
import 'package:flock/features/onboarding/domain/entities/gender.dart';

/// User profile domain entity.
///
/// Represents the user's profile information after onboarding.
final class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.birthday,
    required this.gender,
    this.avatarUrl,
    this.bio,
    this.phoneNumber,
  });

  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String displayName;
  final DateTime birthday;
  final Gender gender;
  final String? avatarUrl;
  final String? bio;
  final String? phoneNumber;

  /// User's initials for avatar fallback.
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        displayName,
        birthday,
        gender,
        avatarUrl,
        bio,
        phoneNumber,
      ];
}
