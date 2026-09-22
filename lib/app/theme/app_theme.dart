import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_colors.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_typography.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';

/// Composes the app's light and dark [ThemeData] from the design tokens in
/// [AppSeedColors]/[AppTypography]/[AppSpacing]. This is the single place a
/// new design token or Material 3 component override should be added.
///
/// `ColorScheme` is the source of truth: every color in the generated
/// theme comes from `ColorScheme.fromSeed` (driven by the user's
/// [PrimaryColorPreference]) — no `primaryColor`/`buttonColor`/`cardColor`
/// style parallel system exists. Only colors genuinely absent from
/// `ColorScheme` would justify a `ThemeExtension` (none needed today).
abstract final class AppTheme {
  static ThemeData light(PrimaryColorPreference primaryColor) =>
      _build(_scheme(primaryColor, Brightness.light));

  static ThemeData dark(PrimaryColorPreference primaryColor) =>
      _build(_scheme(primaryColor, Brightness.dark));

  static ColorScheme _scheme(
    PrimaryColorPreference primaryColor,
    Brightness brightness,
  ) {
    return ColorScheme.fromSeed(
      seedColor: AppSeedColors.resolve(primaryColor),
      brightness: brightness,
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: AppTypography.textTheme(scheme),
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
