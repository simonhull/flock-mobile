import 'package:dio/dio.dart';
import 'package:flock/core/error/failure.dart';
import 'package:flock/core/network/api_client.dart';
import 'package:flock/features/onboarding/data/models/profile_model.dart';
import 'package:flock/features/onboarding/domain/entities/gender.dart';
import 'package:fpdart/fpdart.dart';

/// Remote data source for profile API operations.
abstract interface class ProfileRemoteDataSource {
  /// Get the current user's profile.
  TaskEither<Failure, ProfileModel> getProfile();

  /// Upload an avatar image and return its URL.
  TaskEither<Failure, String> uploadAvatar({
    required List<int> bytes,
    required String mimeType,
  });

  /// Create a new profile.
  TaskEither<Failure, ProfileModel> createProfile({
    required String firstName,
    required String lastName,
    required String birthday,
    required Gender gender,
    String? avatarUrl,
  });
}

/// Implementation using [ApiClient].
final class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  TaskEither<Failure, ProfileModel> getProfile() => _client
      .get('/api/v1/profile')
      .map((json) => ProfileModel.fromJson(json['data'] as Map<String, dynamic>));

  @override
  TaskEither<Failure, String> uploadAvatar({
    required List<int> bytes,
    required String mimeType,
  }) {
    final extension = _mimeToExtension(mimeType);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'avatar.$extension',
      ),
    });

    return _client
        .postMultipart('/api/v1/profile/avatar', formData: formData)
        .map((json) {
      final data = json['data'] as Map<String, dynamic>;
      return data['url'] as String;
    });
  }

  @override
  TaskEither<Failure, ProfileModel> createProfile({
    required String firstName,
    required String lastName,
    required String birthday,
    required Gender gender,
    String? avatarUrl,
  }) =>
      _client
          .post(
            '/api/v1/profile',
            data: {
              'firstName': firstName,
              'lastName': lastName,
              'birthday': birthday,
              'gender': gender.toApiValue(),
              if (avatarUrl != null) 'avatarUrl': avatarUrl,
            },
          )
          .map((json) =>
              ProfileModel.fromJson(json['data'] as Map<String, dynamic>));

  String _mimeToExtension(String mimeType) => switch (mimeType) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };
}
