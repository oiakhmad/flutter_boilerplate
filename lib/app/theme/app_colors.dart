import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';

/// Central seed-color registry for the app theme.
///
/// This is the single place that resolves a [PrimaryColorPreference] into
/// the `Color` seed consumed by `ColorScheme.fromSeed` — nothing else in
/// the app maps presets/custom values to colors, so adding a preset means
/// touching this file only (one enum value in the domain + one entry
/// below).
///
/// Values are Material 3 baseline seed colors; light/dark contrast is left
/// to `ColorScheme.fromSeed`, which guarantees tonal-spot contrast for
/// both brightnesses.
abstract final class AppSeedColors {
  /// Default seed used when persisted data is missing/invalid — the legacy
  /// `AppColors.seed` blue, so existing installs keep their look.
  static const Color defaultSeed = Color(0xFF3D5AFE);

  static const Map<PrimaryColorPreset, Color> presets = {
    PrimaryColorPreset.green: Color(0xFF2E7D32),
    PrimaryColorPreset.blue: Color(0xFF3D5AFE),
    PrimaryColorPreset.brown: Color(0xFF795548),
    PrimaryColorPreset.red: Color(0xFFD32F2F),
    PrimaryColorPreset.orange: Color(0xFFEF6C00),
    PrimaryColorPreset.purple: Color(0xFF7B1FA2),
    PrimaryColorPreset.teal: Color(0xFF00796B),
  };

  /// Resolves a persisted preference to a seed `Color`. Custom ARGB wins
  /// when present; unknown/absent presets fall back to [defaultSeed].
  static Color resolve(PrimaryColorPreference preference) {
    final customArgb = preference.customArgb;
    if (customArgb != null) return Color(customArgb);
    return presets[preference.preset] ?? defaultSeed;
  }
}
