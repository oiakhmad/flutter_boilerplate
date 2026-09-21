import 'package:flutter_clean_boilerplate/core/constants/app_constants.dart';

/// Environment declaration keys understood by the app.
///
/// The values are supplied at build time, never read from disk at runtime:
///
/// ```bash
/// flutter run --dart-define-from-file=config/dev.json
/// flutter run --dart-define-from-file=config/staging.json
/// flutter run --dart-define-from-file=config/production.json
/// ```
///
/// `config/<env>.json` (with committed `*.json.example` twins) is the
/// source of truth for every key listed below.
const String _appEnvKey = 'APP_ENV';
const String _apiBaseUrlKey = 'API_BASE_URL';
const String _appNameKey = 'APP_NAME';
const String _dbNameKey = 'DB_NAME';
const String _enableLoggingKey = 'ENABLE_LOGGING';
const String _apiTimeoutSecondsKey = 'API_TIMEOUT_SECONDS';

/// Environment the app was built for.
///
/// [name] matches the `APP_ENV` value in `config/<env>.json`, so no
/// separate string mapping is needed.
enum AppEnvironment {
  dev,
  staging,
  production;

  /// Parses an `APP_ENV` value, tolerating surrounding whitespace and
  /// casing. Missing or unrecognized input degrades to
  /// [AppEnvironment.dev] instead of failing at startup - the same
  /// defensive `firstWhere(..., orElse:)` posture used by
  /// `AppSettingsModel.fromMap`.
  static AppEnvironment fromName(String raw) {
    final normalized = raw.trim().toLowerCase();
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == normalized,
      orElse: () => AppEnvironment.dev,
    );
  }
}

/// The single place in the app that reads compile-time environment
/// declarations.
///
/// No other class may call `String.fromEnvironment` /
/// `bool.fromEnvironment` / `int.fromEnvironment` (nor `bool.hasEnvironment`),
/// so there is exactly one definition of "what environment are we in" and
/// exactly one definition of "which Sembast file do we open". Everything
/// else depends on the typed getters below:
///
/// ```dart
/// final dbName = AppConfig.dbName;
/// final environment = AppConfig.environment;
/// ```
abstract final class AppConfig {
  // --- Environment ---------------------------------------------------------

  /// Used when `APP_ENV` is absent (app run without an environment
  /// define file) or holds an unrecognized value.
  static const String defaultEnvironmentName = 'dev';

  /// Raw `APP_ENV` declaration, e.g. `dev`.
  static const String environmentName = String.fromEnvironment(
    _appEnvKey,
    defaultValue: defaultEnvironmentName,
  );

  /// [environmentName] as a typed value, resolved once.
  static final AppEnvironment environment =
      AppEnvironment.fromName(environmentName);

  /// Whether an environment define file (or `-D` flags) supplied a
  /// `DB_NAME`. `false` means the app is running with the bundled
  /// fallback values below - useful for tests and for startup logging.
  static const bool isConfigured = bool.hasEnvironment(_dbNameKey);

  static bool get isDev => environment == AppEnvironment.dev;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProduction => environment == AppEnvironment.production;

  // --- Remote API ----------------------------------------------------------

  /// `API_BASE_URL` - base URL of the backend for the active environment.
  /// Empty when the app is run without an environment define file.
  static const String apiBaseUrl = String.fromEnvironment(_apiBaseUrlKey);

  /// `APP_NAME` - environment-specific display name, available for
  /// native/display-name or logging purposes. The in-app title stays
  /// localized (`context.l10n.appTitle`).
  static const String appName = String.fromEnvironment(_appNameKey);

  /// Used when `API_TIMEOUT_SECONDS` is absent or not a valid integer.
  static const int defaultApiTimeoutSeconds = 30;

  /// `API_TIMEOUT_SECONDS` - request timeout for the active environment.
  static const int apiTimeoutSeconds = int.fromEnvironment(
    _apiTimeoutSecondsKey,
    defaultValue: defaultApiTimeoutSeconds,
  );

  /// `ENABLE_LOGGING` - whether verbose logging is allowed in this build.
  static const bool enableLogging = bool.fromEnvironment(_enableLoggingKey);

  // --- Local database ------------------------------------------------------

  /// `DB_NAME` - the Sembast file the app opens for the active
  /// environment:
  ///
  /// | Environment | `DB_NAME`               |
  /// |-------------|-------------------------|
  /// | dev         | `my_app_dev.db`         |
  /// | staging     | `my_app_staging.db`     |
  /// | production  | `my_app_production.db`  |
  ///
  /// Distinct files mean switching environments never reads, mutates, or
  /// overwrites another environment's data.
  ///
  /// Falls back to [AppConstants.databaseFileName] when the app is run
  /// without an environment define file (plain `flutter run`), preserving
  /// the pre-environment behaviour.
  static const String dbName = String.fromEnvironment(
    _dbNameKey,
    defaultValue: AppConstants.databaseFileName,
  );
}
