import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/disable_pin.dart';
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
  Future<Result<void>> savePin(String pin) async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<bool>> verifyPin(String pin) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    if (storedPin == null) {
      return const Result.failure(NotFoundFailure('PIN is not set'));
    }
    return Result.success(storedPin == pin);
  }

  @override
  Future<Result<void>> clearPin() async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedPin = null;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> saveRecoveryAnswer(String answer) async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<bool>> verifyRecoveryAnswer(String answer) async =>
      throw UnimplementedError('not used by this test');
}

void main() {
  late _FakeAppLockRepository repository;
  late DisablePinUseCase useCase;

  setUp(() {
    repository = _FakeAppLockRepository()
      ..storedConfig = AppLockConfig.initial().copyWith(isEnabled: true)
      ..storedPin = '123456';
    useCase = DisablePinUseCase(repository);
  });

  test('keeps the lock and the PIN when the verification fails', () async {
    final result = await useCase('000000');

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockPinIncorrect');
    expect(repository.storedConfig.isEnabled, isTrue);
    expect(repository.storedPin, '123456');
    expect(repository.storedConfig.failedAttempts, 1);
  });

  test('refuses to disable while a lockout window is active', () async {
    repository.storedConfig = repository.storedConfig.copyWith(
      failedAttempts: AppLockConstants.maxFailedAttempts,
      lockoutUntil: DateTime.now().add(AppLockConstants.lockoutDuration),
    );

    final result = await useCase('123456');

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockTooManyAttempts');
    expect(repository.storedConfig.isEnabled, isTrue);
    expect(repository.storedPin, '123456');
  });

  test('disables the lock and removes the PIN when it is correct',
      () async {
    final result = await useCase('123456');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.isEnabled, isFalse);
    expect(repository.storedConfig.isEnabled, isFalse);
    expect(repository.storedPin, isNull,
        reason: 'the PIN must leave secure storage');
    expect(repository.storedConfig.failedAttempts, 0);
    expect(repository.storedConfig.lockoutUntil, isNull);
  });

  test('keeps the recovery question when the lock is turned off', () async {
    repository.storedConfig = repository.storedConfig
        .copyWith(recoveryQuestionId: 'pet');
    repository.storedAnswer = 'Kitty';

    final result = await useCase('123456');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.recoveryQuestionId, 'pet');
    expect(repository.storedAnswer, 'Kitty');
  });

  test('propagates a storage failure', () async {
    repository.shouldFail = true;

    final result = await useCase('123456');

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}