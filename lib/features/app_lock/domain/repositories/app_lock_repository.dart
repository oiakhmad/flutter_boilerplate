import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';

/// Storage contract for the App Lock feature.
///
/// Split in two halves, both hidden behind this interface so the domain
/// never sees where data lives:
///
/// - **config** ([getConfig]/[saveConfig]) - the non-sensitive
///   [AppLockConfig], persisted in Sembast.
/// - **secrets** ([savePin]/[verifyPin]/[clearPin],
///   [saveRecoveryAnswer]/[verifyRecoveryAnswer]) - the PIN and the recovery
///   answer, persisted in the platform secure storage. The repository
///   exposes secrets only as "write" or "verify" operations; nothing above
///   the data layer ever reads a stored secret back.
abstract interface class AppLockRepository {
  /// Loads the App Lock config, falling back to [AppLockConfig.initial]
  /// when nothing has been stored yet (state normal, not a failure).
  Future<Result<AppLockConfig>> getConfig();

  /// Persists [config] and returns the stored result.
  Future<Result<AppLockConfig>> saveConfig(AppLockConfig config);

  /// Stores the 6-digit PIN in secure storage (overwriting any previous
  /// one). The PIN itself never leaves the data layer.
  Future<Result<void>> savePin(String pin);

  /// Checks [pin] against the stored PIN.
  ///
  /// - [Success] `true` - matches.
  /// - [Success] `false` - does not match.
  /// - [NotFoundFailure] - no PIN has been stored (lock never enabled).
  Future<Result<bool>> verifyPin(String pin);

  /// Removes the stored PIN (used when the lock is turned off).
  Future<Result<void>> clearPin();

  /// Stores the recovery answer in secure storage.
  Future<Result<void>> saveRecoveryAnswer(String answer);

  /// Checks [answer] against the stored recovery answer. Same result
  /// contract as [verifyPin].
  Future<Result<bool>> verifyRecoveryAnswer(String answer);
}