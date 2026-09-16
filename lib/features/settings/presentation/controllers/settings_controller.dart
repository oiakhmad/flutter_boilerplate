import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/get_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_language.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_theme_mode.dart';

/// Owns the persisted [AppSettings] and exposes it in Flutter's own
/// vocabulary (`ThemeMode`, `Locale`) for `MaterialApp` to consume
/// directly. This is the one place the domain's Flutter-free
/// [AppThemeMode]/language-code pair is translated into framework types.
///
/// Loaded once during app startup (see `app/di`/`main.dart`) so the first
/// frame already reflects the user's saved preference instead of flashing
/// the default theme/locale.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required GetSettingsUseCase getSettings,
    required UpdateThemeModeUseCase updateThemeMode,
    required UpdateLanguageUseCase updateLanguage,
  })  : _getSettings = getSettings,
        _updateThemeMode = updateThemeMode,
        _updateLanguage = updateLanguage;

  final GetSettingsUseCase _getSettings;
  final UpdateThemeModeUseCase _updateThemeMode;
  final UpdateLanguageUseCase _updateLanguage;

  AppSettings _settings = AppSettings.initial();
  AppSettings get settings => _settings;

  ThemeMode get themeMode => switch (_settings.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  Locale get locale => Locale(_settings.languageCode);

  /// Loads persisted settings. Failure here is intentionally non-fatal -
  /// the controller falls back to [AppSettings.initial] so the app is
  /// always usable even if local storage is unavailable on first launch.
  Future<void> load() async {
    final result = await _getSettings();
    _settings = result.valueOrNull ?? AppSettings.initial();
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final result = await _updateThemeMode(_settings, mode);
    result.fold((_) {}, (updated) {
      _settings = updated;
      notifyListeners();
    });
  }

  Future<void> setLanguageCode(String languageCode) async {
    final result = await _updateLanguage(_settings, languageCode);
    result.fold((_) {}, (updated) {
      _settings = updated;
      notifyListeners();
    });
  }
}
