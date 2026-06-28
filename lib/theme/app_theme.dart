import 'package:flutter/material.dart';

/// App-wide dark theme. Matches the spec's black-background aesthetic
/// used throughout onboarding (Step 1 splash, Step 21 milestone, etc.).
class AppTheme {
  AppTheme._();

  static const Color _bg = Color(0xFF000000);
  static const Color _surface = Color(0xFF0F0F0F);
  static const Color _primary = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF7C5CFF); // gem purple
  static const Color _muted = Color(0xFF8A8A8E);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          surface: _surface,
          primary: _primary,
          secondary: _accent,
          onSurface: _primary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: _primary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _primary, fontSize: 16, height: 1.4),
          bodyMedium: TextStyle(color: _muted, fontSize: 14, height: 1.4),
          titleLarge: TextStyle(
            color: _primary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            color: _primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          labelLarge: TextStyle(
            color: _primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: _bg,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            side: const BorderSide(color: _muted, width: 1),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
}
