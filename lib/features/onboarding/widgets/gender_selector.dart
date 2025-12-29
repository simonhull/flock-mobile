import 'package:flock/features/onboarding/domain/entities/gender.dart';
import 'package:flutter/material.dart';

/// Gender selection buttons.
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    required this.onGenderSelected,
    super.key,
    this.selectedGender,
    this.enabled = true,
  });

  final Gender? selectedGender;
  final ValueChanged<Gender> onGenderSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Gender',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
        Row(
          children: [
            _GenderButton(
              label: 'Male',
              selected: selectedGender == Gender.male,
              enabled: enabled,
              onTap: () => onGenderSelected(Gender.male),
            ),
            const SizedBox(width: 8),
            _GenderButton(
              label: 'Female',
              selected: selectedGender == Gender.female,
              enabled: enabled,
              onTap: () => onGenderSelected(Gender.female),
            ),
            const SizedBox(width: 8),
            _GenderButton(
              label: 'Prefer not to say',
              selected: selectedGender == Gender.preferNotToSay,
              enabled: enabled,
              onTap: () => onGenderSelected(Gender.preferNotToSay),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : null,
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colorScheme.onPrimary : null,
                fontWeight: selected ? FontWeight.w500 : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
