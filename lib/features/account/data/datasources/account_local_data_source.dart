import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';

/// Talks to [DatabaseStore] on behalf of the Account feature.
///
/// This is the only class allowed to know the account store's name and
/// record id (see [StorageKeys]). It throws [DatabaseException] on
/// failure - translation into a domain [Failure] happens one layer up, in
/// [AccountRepositoryImpl].
class AccountLocalDataSource {
  AccountLocalDataSource(this._store);

  final DatabaseStore<AccountModel> _store;

  Future<AccountModel?> getAccount() {
    return _store.getById(StorageKeys.currentAccountId);
  }

  Future<void> saveAccount(AccountModel model) {
    return _store.put(StorageKeys.currentAccountId, model);
  }
}
