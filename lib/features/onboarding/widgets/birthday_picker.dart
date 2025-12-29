import 'package:flutter/material.dart';

/// Birthday date picker field.
class BirthdayPicker extends StatelessWidget {
  const BirthdayPicker({
    required this.onDateSelected,
    super.key,
    this.selectedDate,
    this.enabled = true,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final bool enabled;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = selectedDate ?? DateTime(now.year - 18);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Select your birthday',
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? () => _selectDate(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Birthday',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(
              selectedDate != null
                  ? _formatDate(selectedDate!)
                  : 'Select your birthday',
              style: TextStyle(
                color: selectedDate != null ? null : colorScheme.outline,
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
