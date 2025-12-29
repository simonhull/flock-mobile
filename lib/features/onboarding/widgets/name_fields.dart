import 'package:flutter/material.dart';

/// First and last name input fields.
class NameFields extends StatelessWidget {
  const NameFields({
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    super.key,
    this.enabled = true,
  });

  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'First name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            enabled: enabled,
            onChanged: onFirstNameChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Last name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            enabled: enabled,
            onChanged: onLastNameChanged,
          ),
        ),
      ],
    );
  }
}
