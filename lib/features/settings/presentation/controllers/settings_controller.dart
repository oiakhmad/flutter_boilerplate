import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_theme.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/get_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_language.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_primary_color.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_theme_mode.dart';

/// Owns the persisted [AppSettings] and exposes it in Flutter's own
/// vocabulary (`ThemeMode`, `Locale`, `ThemeData`) for `MaterialApp` to
/// consume directly. This is the one place the domain's Flutter-free
/// [AppThemeMode]/language-code/primary-color triple is translated into
/// framework types.
///
/// Loaded once during app startup (see `app/di`/`main.dart`) so the first
/// frame already reflects the user's saved preference instead of flashing
/// the default theme/locale.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required GetSettingsUseCase getSettings,
    required UpdateThemeModeUseCase updateThemeMode,
    required UpdateLanguageUseCase updateLanguage,
    required UpdatePrimaryColorUseCase updatePrimaryColor,
  })  : _getSettings = getSettings,
        _updateThemeMode = updateThemeMode,
        _updateLanguage = updateLanguage,
        _updatePrimaryColor = updatePrimaryColor;

  final GetSettingsUseCase _getSettings;
  final UpdateThemeModeUseCase _updateThemeMode;
  final UpdateLanguageUseCase _updateLanguage;
  final UpdatePrimaryColorUseCase _updatePrimaryColor;

  AppSettings _settings = AppSettings.initial();
  AppSettings get settings => _settings;

  ThemeMode get themeMode => switch (_settings.themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  Locale get locale => Locale(_settings.languageCode);

  /// `ColorScheme`-derived themes for both brightnesses, rebuilt from the
  /// current seed preference on every `notifyListeners`. `MaterialApp`
  /// consumes these directly; `ThemeMode.system` keeps following the
  /// device setting in real time because the framework re-resolves
  /// `theme` vs `darkTheme` on every platform brightness change.
  ThemeData get lightTheme => AppTheme.light(_settings.primaryColor);

  ThemeData get darkTheme => AppTheme.dark(_settings.primaryColor);

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

  /// Persists a preset choice (e.g. green/blue/...) as an identifier.
  /// On success the new `lightTheme`/`darkTheme` take effect app-wide
  /// without restart via the `Consumer<SettingsController>` in `App`.
  Future<void> setPrimaryColorPreset(PrimaryColorPreset preset) async {
    await _applyPrimaryColor(PrimaryColorPreference.preset(preset));
  }

  /// Persists an exact custom color as ARGB. The custom value becomes the
  /// `ColorScheme.fromSeed` seed — the full scheme is regenerated, not
  /// just `primary` overridden.
  Future<void> setCustomPrimaryColor(Color color) async {
    // `Color.value` is deprecated in newer Flutter; the replacement
    // `toARGB32()` exists only there, so compute ARGB manually to stay
    // compatible with the project's minimum SDK (>=3.19).
    final argb = (((color.a * 255).round() & 0xFF) << 24) |
        (((color.r * 255).round() & 0xFF) << 16) |
        (((color.g * 255).round() & 0xFF) << 8) |
        ((color.b * 255).round() & 0xFF);
    await _applyPrimaryColor(PrimaryColorPreference.custom(argb));
  }

  Future<void> _applyPrimaryColor(PrimaryColorPreference preference) async {
    final result = await _updatePrimaryColor(_settings, preference);
    result.fold((_) {}, (updated) {
      _settings = updated;
      notifyListeners();
    });
  }
}
