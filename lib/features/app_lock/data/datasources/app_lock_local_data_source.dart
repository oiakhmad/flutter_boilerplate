import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/models/app_lock_config_model.dart';

/// Talks to [DatabaseStore] on behalf of the App Lock feature for the
/// **non-sensitive** half of its state (the config record).
///
/// This is the only class that knows the App Lock store name and record id
/// (see [StorageKeys]). It throws [DatabaseException] on failure -
/// translation into a domain [Failure] happens one layer up, in
/// [AppLockRepositoryImpl]. Secrets (PIN, recovery answer) are handled by
/// `AppLockSecureDataSource`, never here.
class AppLockLocalDataSource {
  AppLockLocalDataSource(this._store);

  final DatabaseStore<AppLockConfigModel> _store;

  Future<AppLockConfigModel?> getConfig() {
    return _store.getById(StorageKeys.appLockConfigId);
  }

  Future<void> saveConfig(AppLockConfigModel model) {
    return _store.put(StorageKeys.appLockConfigId, model);
  }
}