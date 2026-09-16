import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';

class AppSettingsModel {
  const AppSettingsModel({required this.themeMode, required this.languageCode});

  final AppThemeMode themeMode;
  final String languageCode;

  factory AppSettingsModel.fromEntity(AppSettings settings) => AppSettingsModel(
        themeMode: settings.themeMode,
        languageCode: settings.languageCode,
      );

  AppSettings toEntity() => AppSettings(themeMode: themeMode, languageCode: languageCode);

  factory AppSettingsModel.fromMap(String id, Map<String, Object?> map) {
    return AppSettingsModel(
      themeMode: AppThemeMode.values.firstWhere(
        (m) => m.name == map['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      languageCode: map['languageCode'] as String? ?? 'en',
    );
  }

  Map<String, Object?> toMap() => {
        'themeMode': themeMode.name,
        'languageCode': languageCode,
      };
}
