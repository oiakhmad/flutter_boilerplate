import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/datasources/app_lock_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/datasources/app_lock_secure_data_source.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/models/app_lock_config_model.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fakes for the two data sources: no mocking framework, no
/// real Sembast, no platform channels.
class _FakeLocalSource implements AppLockLocalDataSource {
  AppLockConfigModel? stored;
  bool shouldThrow = false;

  @override
  Future<AppLockConfigModel?> getConfig() async {
    if (shouldThrow) {
      throw const DatabaseException('Failed to read record');
    }
    return stored;
  }

  @override
  Future<void> saveConfig(AppLockConfigModel model) async {
    if (shouldThrow) {
      throw const DatabaseException('Failed to write record');
    }
    stored = model;
  }
}

class _FakeSecureSource implements AppLockSecureDataSource {
  String? pin;
  String? answer;
  bool shouldThrow = false;

  void _guard() {
    if (shouldThrow) {
      throw const DatabaseException('Secure storage read failed');
    }
  }

  @override
  Future<void> writePin(String value) async {
    _guard();
    pin = value;
  }

  @override
  Future<String?> readPin() async {
    _guard();
    return pin;
  }

  @override
  Future<void> deletePin() async {
    _guard();
    pin = null;
  }

  @override
  Future<void> writeRecoveryAnswer(String value) async {
    _guard();
    answer = value;
  }

  @override
  Future<String?> readRecoveryAnswer() async {
    _guard();
    return answer;
  }
}

void main() {
  late _FakeLocalSource local;
  late _FakeSecureSource secure;
  late AppLockRepositoryImpl repository;

  setUp(() {
    local = _FakeLocalSource();
    secure = _FakeSecureSource();
    repository = AppLockRepositoryImpl(local, secure);
  });

  group('config (Sembast half)', () {
    test('getConfig falls back to the initial config when nothing is stored',
        () async {
      final result = await repository.getConfig();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, AppLockConfig.initial());
    });

    test('getConfig returns the stored config', () async {
      local.stored = AppLockConfigModel.fromEntity(
        const AppLockConfig(
          isEnabled: true,
          recoveryQuestionId: 'pet',
          failedAttempts: 2,
          lockoutUntil: null,
        ),
      );

      final result = await repository.getConfig();

      expect(result.valueOrNull!.isEnabled, isTrue);
      expect(result.valueOrNull!.recoveryQuestionId, 'pet');
      expect(result.valueOrNull!.failedAttempts, 2);
    });

    test('saveConfig translates a DatabaseException into DatabaseFailure',
        () async {
      local.shouldThrow = true;

      final result = await repository.saveConfig(AppLockConfig.initial());

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<DatabaseFailure>());
    });
  });

  group('secrets (secure-storage half)', () {
    test('verifyPin reports a missing PIN as NotFoundFailure', () async {
      final result = await repository.verifyPin('123456');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('verifyPin returns match/mismatch without exposing the stored PIN',
        () async {
      await repository.savePin('123456');

      final match = await repository.verifyPin('123456');
      final mismatch = await repository.verifyPin('000000');

      expect(match.valueOrNull, isTrue);
      expect(mismatch.valueOrNull, isFalse);
    });

    test('clearPin removes the stored PIN', () async {
      await repository.savePin('123456');
      final cleared = await repository.clearPin();
      final verify = await repository.verifyPin('123456');

      expect(cleared.isSuccess, isTrue);
      expect(verify.failureOrNull, isA<NotFoundFailure>());
    });

    test('secure-storage errors are translated into DatabaseFailure',
        () async {
      secure.shouldThrow = true;

      final save = await repository.savePin('123456');
      final verify = await repository.verifyPin('123456');
      final saveAnswer = await repository.saveRecoveryAnswer('Bandung');
      final verifyAnswer = await repository.verifyRecoveryAnswer('Bandung');
      final clear = await repository.clearPin();

      for (final result in [save, verify, saveAnswer, verifyAnswer, clear]) {
        expect(result.failureOrNull, isA<DatabaseFailure>());
      }
    });

    test('recovery answer round-trips like the PIN', () async {
      final missing = await repository.verifyRecoveryAnswer('Bandung');
      await repository.saveRecoveryAnswer('Bandung');
      final match = await repository.verifyRecoveryAnswer('Bandung');
      final mismatch = await repository.verifyRecoveryAnswer('Jakarta');

      expect(missing.failureOrNull, isA<NotFoundFailure>());
      expect(match.valueOrNull, isTrue);
      expect(mismatch.valueOrNull, isFalse);
    });

    test('savePin propagates a secure-storage failure', () async {
      secure.shouldThrow = true;

      final result = await repository.savePin('123456');

      expect(result.failureOrNull, isA<DatabaseFailure>());
      expect(secure.pin, isNull);
    });
  });
}