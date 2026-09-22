import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/core/database/local_database.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';

/// Talks to [DatabaseStore] on behalf of the Account feature.
///
/// This is the only class allowed to know the account store's name and
/// record id (see [StorageKeys]). It throws [DatabaseException] on
/// failure - translation into a domain [Failure] happens one layer up, in
/// [AccountRepositoryImpl].
class AccountLocalDataSource {
  AccountLocalDataSource(this._store, this._database);

  final DatabaseStore<AccountModel> _store;
  final LocalDatabase _database;

  Future<AccountModel?> getAccount() {
    return _store.getById(StorageKeys.currentAccountId);
  }

  Future<void> saveAccount(AccountModel model) {
    return _store.put(StorageKeys.currentAccountId, model);
  }

  /// Deletes the whole local database file (account + all other local
  /// data). Delegates to [LocalDatabase.deleteDatabase], which closes any
  /// open handle first and removes the file asynchronously - so it is kept
  /// off the UI-critical path and never leaves a partially-deleted file
  /// behind on failure.
  Future<void> deleteAllLocalData() => _database.deleteDatabase();
}
