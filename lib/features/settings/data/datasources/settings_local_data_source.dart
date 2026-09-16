import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/models/app_settings_model.dart';

class SettingsLocalDataSource {
  SettingsLocalDataSource(this._store);

  final DatabaseStore<AppSettingsModel> _store;

  Future<AppSettingsModel?> getSettings() {
    return _store.getById(StorageKeys.appSettingsId);
  }

  Future<void> saveSettings(AppSettingsModel model) {
    return _store.put(StorageKeys.appSettingsId, model);
  }
}
