import 'dart:async';

import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart' hide DatabaseException;
import 'package:sembast/sembast_io.dart' hide DatabaseException;

/// Owns the single Sembast [Database] instance for the whole app.
///
/// - Opened exactly once, lazily, on first use.
/// - Every [DatabaseStore] shares this same connection instead of opening
///   its own, so the app never pays the cost of repeated file opens.
/// - Centralizes the on-disk file name/location, so it is the one place
///   that changes if storage location strategy ever changes.
class LocalDatabase {
  LocalDatabase({this.fileName = 'app_database.db'});

  final String fileName;

  Database? _database;
  Completer<Database>? _opening;

  /// Returns the open [Database], opening it on first call.
  ///
  /// Concurrent callers during initialization all await the same
  /// in-flight open rather than racing to open the file twice.
  Future<Database> get instance async {
    final existing = _database;
    if (existing != null) return existing;

    final inFlight = _opening;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<Database>();
    _opening = completer;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = p.join(directory.path, fileName);
      final database = await databaseFactoryIo.openDatabase(dbPath);
      _database = database;
      completer.complete(database);
      return database;
    } catch (error, stackTrace) {
      completer.completeError(
        DatabaseException('Failed to open local database', error),
        stackTrace,
      );
      _opening = null;
      rethrow;
    }
  }

  /// Closes the database. Intended for app shutdown / tests only - regular
  /// feature code should never need to call this.
  Future<void> close() async {
    final database = _database;
    if (database == null) return;
    await database.close();
    _database = null;
    _opening = null;
  }
}
