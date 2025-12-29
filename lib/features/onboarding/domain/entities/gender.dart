/// Gender options for user profiles.
enum Gender {
  male,
  female,
  preferNotToSay;

  /// API representation of this gender.
  String toApiValue() => switch (this) {
        Gender.male => 'male',
        Gender.female => 'female',
        Gender.preferNotToSay => 'prefer_not_to_say',
      };

  /// Parse from API value.
  static Gender fromApiValue(String value) => switch (value) {
        'male' => Gender.male,
        'female' => Gender.female,
        'prefer_not_to_say' => Gender.preferNotToSay,
        _ => Gender.preferNotToSay,
      };
}
