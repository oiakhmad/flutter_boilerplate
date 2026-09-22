import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_pin.dart';
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
  late VerifyPinUseCase useCase;

  setUp(() {
    repository = _FakeAppLockRepository()
      ..storedConfig = AppLockConfig.initial().copyWith(isEnabled: true)
      ..storedPin = '123456';
    useCase = VerifyPinUseCase(repository);
  });

  test('accepts the correct PIN and resets the attempt counter', () async {
    repository.storedConfig =
        repository.storedConfig.copyWith(failedAttempts: 2);

    final result = await useCase('123456');

    expect(result.isSuccess, isTrue);
    expect(repository.storedConfig.failedAttempts, 0);
    expect(repository.storedConfig.lockoutUntil, isNull);
  });

  test('rejects a wrong PIN and counts the attempt', () async {
    final result = await useCase('999999');

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockPinIncorrect');
    expect(repository.storedConfig.failedAttempts, 1);
    expect(repository.storedConfig.lockoutUntil, isNull,
        reason: 'no lockout before the attempt budget is exhausted');
  });

  test('locks out after the maximum number of failed attempts', () async {
    for (var i = 0; i < AppLockConstants.maxFailedAttempts; i++) {
      final result = await useCase('000000');
      final failure = result.failureOrNull as ValidationFailure;
      expect(failure.fieldErrors['pin'], 'appLockPinIncorrect');
    }

    expect(repository.storedConfig.lockoutUntil, isNotNull,
        reason: 'the final allowed failure starts the lockout window');
  });

  test('blocks verification - even with the correct PIN - during lockout',
      () async {
    final locked = repository.storedConfig.copyWith(
      failedAttempts: AppLockConstants.maxFailedAttempts,
      lockoutUntil: DateTime.now().add(AppLockConstants.lockoutDuration),
    );
    repository.storedConfig = locked;

    final result = await useCase('123456');

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockTooManyAttempts');
    expect(repository.storedConfig.failedAttempts,
        AppLockConstants.maxFailedAttempts,
        reason: 'a blocked attempt must not change the counter');
  });

  test('an expired lockout resets the attempt budget and verifies again',
      () async {
    repository.storedConfig = repository.storedConfig.copyWith(
      failedAttempts: AppLockConstants.maxFailedAttempts,
      lockoutUntil: DateTime.now().subtract(const Duration(seconds: 1)),
    );

    final result = await useCase('123456');

    expect(result.isSuccess, isTrue);
    expect(repository.storedConfig.failedAttempts, 0);
    expect(repository.storedConfig.lockoutUntil, isNull);
  });

  test('reports a missing stored PIN as NotFoundFailure', () async {
    repository.storedPin = null;

    final result = await useCase('123456');

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('propagates a storage failure', () async {
    repository.shouldFail = true;

    final result = await useCase('123456');

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}