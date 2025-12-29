import 'package:flock/core/error/failure.dart';
import 'package:flock/features/onboarding/domain/entities/create_profile_params.dart';
import 'package:flock/features/onboarding/domain/entities/profile.dart';
import 'package:fpdart/fpdart.dart';

/// Repository interface for profile operations.
///
/// Abstracts the data layer from domain logic.
/// Implementations handle API calls, caching, etc.
abstract interface class ProfileRepository {
  /// Get the current user's profile.
  ///
  /// Returns [NotFoundFailure] if profile doesn't exist (needs onboarding).
  TaskEither<Failure, Profile> getProfile();

  /// Create a new profile.
  ///
  /// Handles avatar upload if [params.hasAvatar] is true.
  TaskEither<Failure, Profile> createProfile(CreateProfileParams params);

  /// Check if the current user has completed onboarding.
  TaskEither<Failure, bool> hasCompletedOnboarding();
}
