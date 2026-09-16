import 'package:flutter/material.dart';

/// Centralized [TextTheme] so headline/body/label styling stays consistent
/// across every feature instead of ad-hoc `TextStyle(fontSize: ...)` calls.
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme scheme) {
    return const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4),
      labelLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
  }
}
