import 'package:equatable/equatable.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';

/// Domain-owned theme preference.
///
/// Deliberately not `dart:ui`'s `ThemeMode` - the domain layer must stay
/// free of Flutter, so it defines its own vocabulary and the presentation
/// layer maps it to `ThemeMode` at the boundary (see
/// `SettingsController`).
enum AppThemeMode { system, light, dark }

/// Domain entity for persisted app preferences.
class AppSettings extends Equatable {
  const AppSettings({
    required this.themeMode,
    required this.languageCode,
    required this.primaryColor,
  });

  factory AppSettings.initial() => const AppSettings(
        themeMode: AppThemeMode.system,
        languageCode: 'en',
        primaryColor: PrimaryColorPreference.defaultPreset(),
      );

  final AppThemeMode themeMode;

  /// ISO 639-1 code, e.g. 'en' / 'id'. Kept as a plain string rather than
  /// `dart:ui`'s `Locale` for the same reason as [themeMode].
  final String languageCode;

  /// Seed-color preference used to derive both light and dark
  /// `ColorScheme`s via `ColorScheme.fromSeed`.
  final PrimaryColorPreference primaryColor;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? languageCode,
    PrimaryColorPreference? primaryColor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  @override
  List<Object?> get props => [themeMode, languageCode, primaryColor];
}
