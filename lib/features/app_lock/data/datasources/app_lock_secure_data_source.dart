import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Talks to the platform secure storage (Android Keystore / iOS Keychain)
/// on behalf of the App Lock feature.
///
/// The **only** class that handles the App Lock secrets (the 6-digit PIN
/// and the recovery answer). Design rules:
///
/// - secrets never go to Sembast, SharedPreferences, or the console -
///   this source is their single entry/exit point in the whole app;
/// - the key names are private constants here so no other file can reach
///   into the vault;
/// - platform errors are wrapped in [DatabaseException] so the repository
///   can translate them with the same `DatabaseException -> DatabaseFailure`
///   pipeline used for Sembast - no raw platform exception ever escapes
///   the data layer. Error messages never include the stored value.
class AppLockSecureDataSource {
  AppLockSecureDataSource({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _pinKey = 'app_lock_pin';
  static const String _recoveryAnswerKey = 'app_lock_recovery_answer';

  final FlutterSecureStorage _storage;

  Future<void> writePin(String pin) => _write(_pinKey, pin);

  Future<String?> readPin() => _read(_pinKey);

  Future<void> deletePin() => _delete(_pinKey);

  Future<void> writeRecoveryAnswer(String answer) =>
      _write(_recoveryAnswerKey, answer);

  Future<String?> readRecoveryAnswer() => _read(_recoveryAnswerKey);

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      throw DatabaseException('Secure storage write failed', error);
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error) {
      throw DatabaseException('Secure storage read failed', error);
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      throw DatabaseException('Secure storage delete failed', error);
    }
  }
}