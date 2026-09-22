import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/change_pin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake, matching the account/settings test convention: no
/// mocking framework, no database, no secure storage.
class _FakeAppLockRepository implements AppLockRepository {
  AppLockConfig storedConfig = AppLockConfig.initial();
  String? storedPin;
  String? storedAnswer;
  bool shouldFail = false;

  @override
  Future<Result<AppLockConfig>> getConfig() async =>
      shouldFail ? const Result.failure(DatabaseFailure('disk full')) : Result.success(storedConfig);

  @override
  Future<Result<AppLockConfig>> saveConfig(AppLockConfig config) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedConfig = config;
    return Result.success(config);
  }

  @override
  Future<Result<void>> savePin(String pin) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedPin = pin;
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> verifyPin(String pin) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    if (storedPin == null) {
      return const Result.failure(NotFoundFailure('PIN is not set'));
    }
    return Result.success(storedPin == pin);
  }

  @override
  Future<Result<void>> clearPin() async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<void>> saveRecoveryAnswer(String answer) async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<bool>> verifyRecoveryAnswer(String answer) async =>
      throw UnimplementedError('not used by this test');
}

void main() {
  late _FakeAppLockRepository repository;
  late ChangePinUseCase useCase;

  setUp(() {
    repository = _FakeAppLockRepository()
      ..storedConfig = AppLockConfig.initial().copyWith(isEnabled: true)
      ..storedPin = '123456';
    useCase = ChangePinUseCase(repository);
  });

  test('rejects a wrong old PIN without touching the stored one', () async {
    final result = await useCase(
      const ChangePinParams(
        oldPin: '999999',
        newPin: '654321',
        confirmNewPin: '654321',
      ),
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockPinIncorrect');
    expect(repository.storedPin, '123456');
  });

  test('validates the new PIN only after the old one is verified',
      () async {
    final result = await useCase(
      const ChangePinParams(
        oldPin: '123456',
        newPin: '123',
        confirmNewPin: '123',
      ),
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['newPin'], 'appLockPinInvalid');
    expect(repository.storedPin, '123456');
  });

  test('rejects a new PIN whose confirmation does not match', () async {
    final result = await useCase(
      const ChangePinParams(
        oldPin: '123456',
        newPin: '654321',
        confirmNewPin: '6543211',
      ),
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['confirmNewPin'], 'appLockPinMismatch');
    expect(repository.storedPin, '123456');
  });

  test('replaces the PIN when everything is correct', () async {
    final result = await useCase(
      const ChangePinParams(
        oldPin: '123456',
        newPin: '654321',
        confirmNewPin: '654321',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.storedPin, '654321');

    // The old PIN no longer verifies; the new one does.
    final oldCheck = await repository.verifyPin('123456');
    final newCheck = await repository.verifyPin('654321');
    expect(oldCheck.valueOrNull, isFalse);
    expect(newCheck.valueOrNull, isTrue);
  });

  test('propagates a storage failure', () async {
    repository.shouldFail = true;

    final result = await useCase(
      const ChangePinParams(
        oldPin: '123456',
        newPin: '654321',
        confirmNewPin: '654321',
      ),
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}