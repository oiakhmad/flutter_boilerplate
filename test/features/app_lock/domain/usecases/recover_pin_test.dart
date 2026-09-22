import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/recover_pin.dart';
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
  Future<Result<bool>> verifyRecoveryAnswer(String answer) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    if (storedAnswer == null) {
      return const Result.failure(
        NotFoundFailure('Recovery answer is not set'),
      );
    }
    return Result.success(storedAnswer == answer.trim());
  }
}

void main() {
  late _FakeAppLockRepository repository;
  late RecoverPinUseCase useCase;

  setUp(() {
    repository = _FakeAppLockRepository()
      ..storedConfig = AppLockConfig.initial().copyWith(
        isEnabled: true,
        recoveryQuestionId: 'city',
        failedAttempts: AppLockConstants.maxFailedAttempts,
        lockoutUntil: DateTime.now().add(AppLockConstants.lockoutDuration),
      )
      ..storedPin = '123456'
      ..storedAnswer = 'Bandung';
    useCase = RecoverPinUseCase(repository);
  });

  test('validates the new PIN before the answer is ever checked',
      () async {
    final result = await useCase(
      const RecoverPinParams(
        answer: 'Bandung',
        newPin: '12',
        confirmNewPin: '12',
      ),
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['newPin'], 'appLockPinInvalid');
    expect(repository.storedPin, '123456');
    expect(repository.saveConfigCalls, 0);
  });

  test('rejects a confirmation mismatch before the answer is checked',
      () async {
    final result = await useCase(
      const RecoverPinParams(
        answer: 'Bandung',
        newPin: '654321',
        confirmNewPin: '654320',
      ),
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['confirmNewPin'], 'appLockPinMismatch');
    expect(repository.storedPin, '123456');
  });

  test('rejects a wrong recovery answer and keeps the PIN', () async {
    final result = await useCase(
      const RecoverPinParams(
        answer: 'Jakarta',
        newPin: '654321',
        confirmNewPin: '654321',
      ),
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['answer'], 'appLockAnswerIncorrect');
    expect(repository.storedPin, '123456');
    expect(repository.saveConfigCalls, 0);
  });

  test('replaces the PIN and clears the lockout on a correct answer',
      () async {
    final result = await useCase(
      const RecoverPinParams(
        answer: ' Bandung ',
        newPin: '654321',
        confirmNewPin: '654321',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.storedPin, '654321');
    expect(result.valueOrNull!.isEnabled, isTrue,
        reason: 'recovery keeps the lock engaged');
    expect(result.valueOrNull!.recoveryQuestionId, 'city',
        reason: 'the recovery configuration is untouched');
    expect(result.valueOrNull!.failedAttempts, 0);
    expect(result.valueOrNull!.lockoutUntil, isNull);
  });

  test('never touches account or business data', () async {
    // The repository interface only exposes lock config/PIN/answer - this
    // test documents that a successful recovery performs exactly one pin
    // write and one config write, nothing else.
    final result = await useCase(
      const RecoverPinParams(
        answer: 'Bandung',
        newPin: '654321',
        confirmNewPin: '654321',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(repository.saveConfigCalls, 1);
    expect(repository.storedAnswer, 'Bandung',
        reason: 'the recovery answer is kept for future use');
  });

  test('propagates a storage failure', () async {
    repository.shouldFail = true;

    final result = await useCase(
      const RecoverPinParams(
        answer: 'Bandung',
        newPin: '654321',
        confirmNewPin: '654321',
      ),
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}