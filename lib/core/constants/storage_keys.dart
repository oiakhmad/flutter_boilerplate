/// Central registry of Sembast store names and settings keys.
///
/// Keeping every key/store name in one place prevents typo-based bugs
/// (e.g. one file writing to "account" and another reading "accounts").
abstract final class StorageKeys {
  // Sembast store names
  static const String accountStore = 'account_store';
  static const String settingsStore = 'settings_store';

  /// App Lock non-sensitive configuration (enabled flag, recovery question
  /// id, attempt counter). Secrets (PIN, recovery answer) deliberately do
  /// NOT live in Sembast - they go to the platform secure storage, see
  /// `features/app_lock/data/datasources/app_lock_secure_data_source.dart`.
  static const String appLockStore = 'app_lock_store';

  // Record ids
  /// The account feature models a single local user profile, so it is
  /// addressed by a fixed record id rather than a generated one.
  static const String currentAccountId = 'current_account';

  /// Settings are similarly a single-record document.
  static const String appSettingsId = 'app_settings';

  /// App Lock config is also a single-record document.
  static const String appLockConfigId = 'app_lock_config';
}
