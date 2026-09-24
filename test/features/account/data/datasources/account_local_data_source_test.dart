import 'dart:io';

import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/core/database/local_database.dart';
import 'package:flutter_clean_boilerplate/features/account/data/datasources/account_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

class _TempLocalDatabase extends LocalDatabase {
  _TempLocalDatabase(this.directory) : super(fileName: 'input_security.db');

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

void main() {
  late Directory directory;
  late _TempLocalDatabase database;
  late AccountLocalDataSource dataSource;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('account_input_security');
    database = _TempLocalDatabase(directory);
    dataSource = AccountLocalDataSource(
      DatabaseStore<AccountModel>(
        database: database,
        storeName: StorageKeys.accountStore,
        fromMap: AccountModel.fromMap,
        toMap: (model) => model.toMap(),
      ),
      database,
    );
  });

  tearDown(() async {
    await database.close();
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  test('valid profile punctuation round-trips through real Sembast', () async {
    final createdAt = DateTime(2024, 1, 1);
    final model = AccountModel(
      id: 'current_account',
      name: "O'Connor PT. Maju Jaya",
      email: 'first.last+tag@example-domain.com',
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    await dataSource.saveAccount(model);
    final loaded = await dataSource.getAccount();

    expect(loaded?.name, model.name);
    expect(loaded?.email, model.email);
    expect(loaded?.createdAt, createdAt);
  });

  test('user input never becomes a Sembast query string', () async {
    final model = AccountModel(
      id: 'current_account',
      name: "O'Connor",
      email: 'user+tag@example.com',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    await dataSource.saveAccount(model);
    final loaded = await dataSource.getAccount();

    expect(loaded, isNotNull);
    expect(loaded?.name, "O'Connor");
    expect(loaded?.email, 'user+tag@example.com');
  });
}
