import 'package:flutter/material.dart';

/// Flock app theme matching web design system.
///
/// Colors derived from web's OKLch values:
/// - Primary: oklch(0.625 0.145 220) → #0099CC (cyan-blue)
/// - Secondary: oklch(0.648 0.138 155) → #26B170 (green)
/// - Destructive: oklch(0.577 0.245 27.325) → #DC3545 (red)
abstract final class AppTheme {
  // Brand colors
  static const primary = Color(0xFF0099CC);
  static const secondary = Color(0xFF26B170);
  static const destructive = Color(0xFFDC3545);

  // Light mode neutrals
  static const _lightBackground = Color(0xFFFFFFFF);
  static const _lightForeground = Color(0xFF1F1F1F);
  static const _lightMuted = Color(0xFFF7F7F7);
  static const _lightMutedForeground = Color(0xFF6B6B6B);
  static const _lightBorder = Color(0xFFE8E8E8);

  // Dark mode neutrals
  static const _darkBackground = Color(0xFF1F1F1F);
  static const _darkForeground = Color(0xFFFAFAFA);
  static const _darkMuted = Color(0xFF333333);
  static const _darkMutedForeground = Color(0xFF9CA3AF);
  static const _darkBorder = Color(0xFF374151);

  /// Light theme.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          onSecondary: Colors.white,
          error: destructive,
          onError: Colors.white,
          surface: _lightBackground,
          onSurface: _lightForeground,
          surfaceContainerHighest: _lightMuted,
          outline: _lightBorder,
          outlineVariant: _lightMutedForeground,
        ),
        scaffoldBackgroundColor: _lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightBackground,
          foregroundColor: _lightForeground,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: _lightBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: _lightBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: destructive),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _lightForeground,
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: _lightBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _lightBorder,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  /// Dark theme.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          onSecondary: Colors.white,
          error: destructive,
          onError: Colors.white,
          surface: _darkBackground,
          onSurface: _darkForeground,
          surfaceContainerHighest: _darkMuted,
          outline: _darkBorder,
          outlineVariant: _darkMutedForeground,
        ),
        scaffoldBackgroundColor: _darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBackground,
          foregroundColor: _darkForeground,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: _darkMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: _darkBorder.withValues(alpha: 0.1)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: destructive),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _darkForeground,
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: _darkBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: _darkBorder,
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
}
