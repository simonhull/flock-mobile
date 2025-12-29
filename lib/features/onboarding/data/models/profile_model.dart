import 'package:flock/features/onboarding/domain/entities/gender.dart';
import 'package:flock/features/onboarding/domain/entities/profile.dart';

/// Data transfer object for Profile.
///
/// Handles JSON serialization/deserialization.
final class ProfileModel {
  const ProfileModel({
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      displayName: json['displayName'] as String,
      birthday: DateTime.parse(json['birthday'] as String),
      gender: Gender.fromApiValue(json['gender'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

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

  /// Convert to domain entity.
  Profile toEntity() => Profile(
        id: id,
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        birthday: birthday,
        gender: gender,
        avatarUrl: avatarUrl,
        bio: bio,
        phoneNumber: phoneNumber,
      );
}
