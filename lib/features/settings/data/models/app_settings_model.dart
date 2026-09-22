import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';

class AppSettingsModel {
  const AppSettingsModel({
    required this.themeMode,
    required this.languageCode,
    required this.primaryColor,
  });

  final AppThemeMode themeMode;
  final String languageCode;
  final PrimaryColorPreference primaryColor;

  factory AppSettingsModel.fromEntity(AppSettings settings) => AppSettingsModel(
        themeMode: settings.themeMode,
        languageCode: settings.languageCode,
        primaryColor: settings.primaryColor,
      );

  AppSettings toEntity() => AppSettings(
        themeMode: themeMode,
        languageCode: languageCode,
        primaryColor: primaryColor,
      );

  factory AppSettingsModel.fromMap(String id, Map<String, Object?> map) {
    return AppSettingsModel(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == map['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      languageCode: map['languageCode'] as String? ?? 'en',
      primaryColor: _primaryColorFromMap(map),
    );
  }

  /// Defensive decode with full fallback to the default preset:
  ///
  /// - `customArgb` present and a valid 32-bit int → custom color.
  /// - `preset` matching a known [PrimaryColorPreset] name → preset.
  /// - anything else (missing keys, wrong types, unknown preset names
  ///   from a future app version, corrupt data) → default preset.
  /// Never throws, so a bad record can never crash startup.
  static PrimaryColorPreference _primaryColorFromMap(
    Map<String, Object?> map,
  ) {
    final customArgb = map['primaryColorArgb'];
    if (customArgb is int &&
        customArgb >= 0 &&
        customArgb <= 0xFFFFFFFF) {
      return PrimaryColorPreference.custom(customArgb);
    }
    final presetName = map['primaryColorPreset'];
    if (presetName is String) {
      for (final preset in PrimaryColorPreset.values) {
        if (preset.name == presetName) {
          return PrimaryColorPreference.preset(preset);
        }
      }
    }
    return const PrimaryColorPreference.defaultPreset();
  }

  Map<String, Object?> toMap() => {
        'themeMode': themeMode.name,
        'languageCode': languageCode,
        if (primaryColor.customArgb != null)
          'primaryColorArgb': primaryColor.customArgb,
        if (primaryColor.preset != null)
          'primaryColorPreset': primaryColor.preset!.name,
      };
}
