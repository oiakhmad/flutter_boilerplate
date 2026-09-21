import 'dart:io';

import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/core/database/local_database.dart';
import 'package:flutter_clean_boilerplate/features/account/data/datasources/account_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';
import 'package:flutter_clean_boilerplate/features/account/data/repositories/account_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/create_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

/// [LocalDatabase] whose file lives in a directory the test controls.
///
/// `LocalDatabase` resolves its directory through `path_provider`, which
/// needs a platform channel. Overriding just the connection lets this test
/// drive the **real** stack - Sembast file on disk → [DatabaseStore] → data
/// source → repository → use cases → [SplashController] - with no production
/// code modified for testability.
class _TempLocalDatabase extends LocalDatabase {
  _TempLocalDatabase(this.directory) : super(fileName: 'test_account.db');

  final Directory directory;

  Database? _opened;

  @override
  Future<Database> get instance async {
    return _opened ??=
        await databaseFactoryIo.openDatabase(p.join(directory.path, fileName));
  }

  @override
  Future<void> close() async {
    await _opened?.close();
    _opened = null;
  }
}

/// Builds the account chain exactly like `app/di/injector.dart` does, over
/// the given database connection.
AccountRepository _repositoryOver(LocalDatabase database) {
  return AccountRepositoryImpl(
    AccountLocalDataSource(
      DatabaseStore<AccountModel>(
        database: database,
        storeName: StorageKeys.accountStore,
        fromMap: AccountModel.fromMap,
        toMap: (model) => model.toMap(),
      ),
    ),
  );
}

/// A fresh controller over `database` - i.e. one app launch.
SplashController _launch(LocalDatabase database) {
  final repository = _repositoryOver(database);
  return SplashController(
    getAccount: GetAccountUseCase(repository),
    createAccount: CreateAccountUseCase(repository),
  );
}

void main() {
  late Directory directory;
  final openDatabases = <LocalDatabase>[];

  setUp(() {
    directory = Directory.systemTemp.createTempSync('splash_persistence');
    openDatabases.clear();
  });

  tearDown(() async {
    for (final database in openDatabases) {
      await database.close();
    }
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  LocalDatabase newLaunchDatabase() {
    final database = _TempLocalDatabase(directory);
    openDatabases.add(database);
    return database;
  }

  test('the account survives a restart and is stored in Sembast', () async {
    // First launch: nothing stored yet.
    final firstLaunch = _launch(newLaunchDatabase());
    await firstLaunch.load();
    expect(firstLaunch.status, SplashStatus.needsName);

    expect(await firstLaunch.submitName('Budi'), isTrue);
    expect(firstLaunch.hasAccount, isTrue);

    // The record is on disk, in the account feature's own store.
    final file = File(p.join(directory.path, 'test_account.db'));
    expect(file.existsSync(), isTrue);

    // "Restart": close the connection and start over from the file.
    for (final database in openDatabases) {
      await database.close();
    }
    openDatabases.clear();

    final secondLaunch = _launch(newLaunchDatabase());
    await secondLaunch.load();

    expect(secondLaunch.status, SplashStatus.ready);
    expect(secondLaunch.hasAccount, isTrue);
    expect(secondLaunch.account?.name, 'Budi');
    expect(secondLaunch.account?.id, StorageKeys.currentAccountId);
  });

  test('an existing account is never overwritten by the first-run flow',
      () async {
    final firstLaunch = _launch(newLaunchDatabase());
    await firstLaunch.load();
    await firstLaunch.submitName('Budi');

    for (final database in openDatabases) {
      await database.close();
    }
    openDatabases.clear();

    // Second launch: the form is already past, but even a forced submit
    // must not replace the stored account.
    final secondLaunch = _launch(newLaunchDatabase());
    await secondLaunch.load();
    expect(await secondLaunch.submitName('Someone Else'), isTrue);

    for (final database in openDatabases) {
      await database.close();
    }
    openDatabases.clear();

    final thirdLaunch = _launch(newLaunchDatabase());
    await thirdLaunch.load();
    expect(thirdLaunch.account?.name, 'Budi');
  });
}
