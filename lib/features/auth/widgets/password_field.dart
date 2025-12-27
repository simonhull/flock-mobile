import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Password input with visibility toggle.
///
/// Stateful widget to manage obscure text state internally.
final class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.label,
    super.key,
    this.controller,
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

final class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: FaIcon(
            _obscureText ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
          ),
          onPressed: _toggleVisibility,
        ),
      ),
    );
  }
}
