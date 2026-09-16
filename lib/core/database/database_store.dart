import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:flutter_clean_boilerplate/core/database/local_database.dart';
import 'package:sembast/sembast.dart' hide DatabaseException;

/// A typed, reusable wrapper around a single Sembast [StoreRef].
///
/// This is the *only* class in the app that is allowed to talk to Sembast
/// directly. Data sources depend on `DatabaseStore<T>`, never on Sembast
/// APIs, so adding a new entity means adding a new data source that
/// composes this class - not writing raw store/record calls in feature
/// code, and not touching this file.
///
/// [T] is the plain-map-serializable model type. Callers provide
/// `fromMap`/`toMap` so this store stays agnostic of any single entity.
class DatabaseStore<T> {
  DatabaseStore({
    required LocalDatabase database,
    required String storeName,
    required T Function(String id, Map<String, Object?> map) fromMap,
    required Map<String, Object?> Function(T value) toMap,
  })  : _database = database,
        _store = stringMapStoreFactory.store(storeName),
        _fromMap = fromMap,
        _toMap = toMap;

  final LocalDatabase _database;
  final StoreRef<String, Map<String, Object?>> _store;
  final T Function(String id, Map<String, Object?> map) _fromMap;
  final Map<String, Object?> Function(T value) _toMap;

  Future<T?> getById(String id) async {
    try {
      final db = await _database.instance;
      final record = await _store.record(id).get(db);
      if (record == null) return null;
      return _fromMap(id, record);
    } on DatabaseException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to read record "$id"', error);
    }
  }

  Future<List<T>> getAll() async {
    try {
      final db = await _database.instance;
      final records = await _store.find(db);
      return records.map((r) => _fromMap(r.key, r.value)).toList();
    } on DatabaseException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to read all records', error);
    }
  }

  Future<void> put(String id, T value) async {
    try {
      final db = await _database.instance;
      await _store.record(id).put(db, _toMap(value));
    } on DatabaseException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to write record "$id"', error);
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = await _database.instance;
      await _store.record(id).delete(db);
    } on DatabaseException {
      rethrow;
    } catch (error) {
      throw DatabaseException('Failed to delete record "$id"', error);
    }
  }
}
