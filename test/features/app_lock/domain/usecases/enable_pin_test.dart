import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/enable_pin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake, matching the account/settings test convention: no
/// mocking framework, no database, no secure storage.
class _FakeAppLockRepository implements AppLockRepository {
  AppLockConfig storedConfig = AppLockConfig.initial();
  String? storedPin;
  String? storedAnswer;
  int saveConfigCalls = 0;
  bool shouldFail = false;

  @override
  Future<Result<AppLockConfig>> getConfig() async =>
      shouldFail ? const Result.failure(DatabaseFailure('disk full')) : Result.success(storedConfig);

  @override
  Future<Result<AppLockConfig>> saveConfig(AppLockConfig config) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    saveConfigCalls++;
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
  Future<Result<bool>> verifyPin(String pin) async =>
      throw UnimplementedError('not used by this test');

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
  late EnablePinUseCase useCase;

  setUp(() {
    repository = _FakeAppLockRepository();
    useCase = EnablePinUseCase(repository);
  });

  test('rejects a PIN shorter than 6 digits without touching storage',
      () async {
    final result = await useCase(
      const EnablePinParams(pin: '12345', confirmPin: '12345'),
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockPinInvalid');
    expect(repository.saveConfigCalls, 0);
    expect(repository.storedPin, isNull);
    expect(repository.storedConfig.isEnabled, isFalse);
  });

  test('rejects a PIN longer than 6 digits or non-numeric', () async {
    for (final pin in ['1234567', 'abcdef', '12 456', '']) {
      final result = await useCase(
        EnablePinParams(pin: pin, confirmPin: pin),
      );
      final failure = result.failureOrNull as ValidationFailure;
      expect(failure.fieldErrors['pin'], 'appLockPinInvalid',
          reason: 'input "$pin" must be rejected');
    }
    expect(repository.storedPin, isNull);
    expect(repository.saveConfigCalls, 0);
  });

  test('rejects a confirmation that does not match', () async {
    final result = await useCase(
      const EnablePinParams(pin: '123456', confirmPin: '654321'),
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['confirmPin'], 'appLockPinMismatch');
    expect(repository.saveConfigCalls, 0);
    expect(repository.storedPin, isNull);
  });

  test('rejects enabling when the lock is already on', () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '111111';

    final result = await useCase(
      const EnablePinParams(pin: '222222', confirmPin: '222222'),
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockAlreadyEnabled');
    expect(repository.storedPin, '111111', reason: 'PIN must not be replaced');
    expect(repository.saveConfigCalls, 0);
  });

  test('stores the PIN and enables the lock', () async {
    repository.storedConfig = AppLockConfig.initial()
        .copyWith(failedAttempts: 3);

    final result = await useCase(
      const EnablePinParams(pin: '123456', confirmPin: '123456'),
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.isEnabled, isTrue);
    expect(repository.storedPin, '123456');
    expect(repository.storedConfig.isEnabled, isTrue);
    expect(repository.storedConfig.failedAttempts, 0,
        reason: 'the attempt budget starts fresh');
    expect(repository.saveConfigCalls, 1);
  });

  test('propagates a storage failure', () async {
    repository.shouldFail = true;

    final result = await useCase(
      const EnablePinParams(pin: '123456', confirmPin: '123456'),
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
    expect(repository.storedConfig.isEnabled, isFalse);
  });
}