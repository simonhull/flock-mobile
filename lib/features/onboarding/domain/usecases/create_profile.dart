import 'package:flock/core/error/failure.dart';
import 'package:flock/features/onboarding/domain/entities/create_profile_params.dart';
import 'package:flock/features/onboarding/domain/entities/profile.dart';
import 'package:flock/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Use case for creating a new user profile.
///
/// Single responsibility: orchestrate profile creation including avatar upload.
final class CreateProfile {
  const CreateProfile(this._repository);

  final ProfileRepository _repository;

  /// Execute the use case.
  ///
  /// Creates a profile with the given [params].
  /// If avatar bytes are included, they are uploaded first.
  TaskEither<Failure, Profile> call(CreateProfileParams params) =>
      _repository.createProfile(params);
}
