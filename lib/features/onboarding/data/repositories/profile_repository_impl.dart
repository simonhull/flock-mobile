import 'package:flock/core/error/failure.dart';
import 'package:flock/features/onboarding/data/datasources/profile_remote_datasource.dart';
import 'package:flock/features/onboarding/domain/entities/create_profile_params.dart';
import 'package:flock/features/onboarding/domain/entities/profile.dart';
import 'package:flock/features/onboarding/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Implementation of [ProfileRepository].
///
/// Orchestrates data sources to fulfill repository contract.
final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  TaskEither<Failure, Profile> getProfile() =>
      _remoteDataSource.getProfile().map((model) => model.toEntity());

  @override
  TaskEither<Failure, Profile> createProfile(CreateProfileParams params) {
    // If we have an avatar, upload it first, then create profile
    if (params.hasAvatar) {
      return _remoteDataSource
          .uploadAvatar(
            bytes: params.avatarBytes!,
            mimeType: params.avatarMimeType!,
          )
          .flatMap(
            (avatarUrl) => _createProfileWithAvatar(params, avatarUrl),
          );
    }

    // No avatar, create profile directly
    return _createProfileWithAvatar(params, null);
  }

  @override
  TaskEither<Failure, bool> hasCompletedOnboarding() => getProfile()
      .map((_) => true)
      .orElse((_) => TaskEither.right(false));

  TaskEither<Failure, Profile> _createProfileWithAvatar(
    CreateProfileParams params,
    String? avatarUrl,
  ) =>
      _remoteDataSource
          .createProfile(
            firstName: params.firstName,
            lastName: params.lastName,
            birthday: params.birthdayIso,
            gender: params.gender,
            avatarUrl: avatarUrl,
          )
          .map((model) => model.toEntity());
}
