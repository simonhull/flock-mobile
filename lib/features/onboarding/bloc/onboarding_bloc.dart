import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flock/features/onboarding/bloc/onboarding_event.dart';
import 'package:flock/features/onboarding/bloc/onboarding_state.dart';
import 'package:flock/features/onboarding/domain/entities/create_profile_params.dart';
import 'package:flock/features/onboarding/domain/usecases/create_profile.dart';
import 'package:fpdart/fpdart.dart';

/// Bloc for handling user onboarding (profile creation).
///
/// Uses [CreateProfile] use case for business logic.
/// Presentation concerns only: form state and submission orchestration.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required CreateProfile createProfile})
      : _createProfile = createProfile,
        super(const OnboardingState()) {
    on<OnboardingFirstNameChanged>(_onFirstNameChanged);
    on<OnboardingLastNameChanged>(_onLastNameChanged);
    on<OnboardingBirthdayChanged>(_onBirthdayChanged);
    on<OnboardingGenderChanged>(_onGenderChanged);
    on<OnboardingAvatarChanged>(_onAvatarChanged);
    on<OnboardingSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CreateProfile _createProfile;

  void _onFirstNameChanged(
    OnboardingFirstNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(firstName: event.firstName));
  }

  void _onLastNameChanged(
    OnboardingLastNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(lastName: event.lastName));
  }

  void _onBirthdayChanged(
    OnboardingBirthdayChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(birthday: event.birthday));
  }

  void _onGenderChanged(
    OnboardingGenderChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(gender: event.gender));
  }

  void _onAvatarChanged(
    OnboardingAvatarChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      state.copyWith(
        avatarBytes: event.bytes,
        avatarMimeType: event.mimeType,
      ),
    );
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: OnboardingStatus.submitting));

    final params = CreateProfileParams(
      firstName: state.firstName.trim(),
      lastName: state.lastName.trim(),
      birthday: state.birthday!,
      gender: state.gender!,
      avatarBytes: state.avatarBytes,
      avatarMimeType: state.avatarMimeType,
    );

    final result = await _createProfile(params).run();

    emit(
      switch (result) {
        Right(:final value) => state.copyWith(
            status: OnboardingStatus.success,
            profile: value,
          ),
        Left(:final value) => state.copyWith(
            status: OnboardingStatus.failure,
            errorMessage: value.message,
          ),
      },
    );
  }
}
