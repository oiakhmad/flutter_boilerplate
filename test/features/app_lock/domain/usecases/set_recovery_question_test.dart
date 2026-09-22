import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/set_recovery_question.dart';
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
  Future<Result<bool>> verifyPin(String pin) async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<void>> clearPin() async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<void>> saveRecoveryAnswer(String answer) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedAnswer = answer;
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> verifyRecoveryAnswer(String answer) async =>
      throw UnimplementedError('not used by this test');
}

void main() {
  late _FakeAppLockRepository repository;
  late SetRecoveryQuestionUseCase useCase;

  setUp(() {
    repository = _FakeAppLockRepository();
    useCase = SetRecoveryQuestionUseCase(repository);
  });

  test('rejects an unknown question id without writing anything', () async {
    final result = await useCase(
      const SetRecoveryQuestionParams(
        questionId: 'not-a-preset',
        answer: 'Bandung',
      ),
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['questionId'], 'appLockQuestionInvalid');
    expect(repository.storedAnswer, isNull);
    expect(repository.saveConfigCalls, 0);
    expect(repository.storedConfig.recoveryQuestionId, isNull);
  });

  test('rejects a blank answer without writing anything', () async {
    final result = await useCase(
      const SetRecoveryQuestionParams(questionId: 'city', answer: '   '),
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['answer'], 'appLockAnswerRequired');
    expect(repository.storedAnswer, isNull);
    expect(repository.saveConfigCalls, 0);
  });

  test('stores the trimmed answer in the vault and the id in the config',
      () async {
    final result = await useCase(
      const SetRecoveryQuestionParams(
        questionId: 'city',
        answer: '  Bandung  ',
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.recoveryQuestionId, 'city');
    expect(repository.storedAnswer, 'Bandung');
    expect(repository.storedConfig.recoveryQuestionId, 'city');
    expect(repository.storedConfig.isEnabled, isFalse,
        reason: 'setting recovery alone must not enable the lock');
  });

  test('replaces a previously configured question and answer', () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(recoveryQuestionId: 'pet');
    repository.storedAnswer = 'Kitty';

    final result = await useCase(
      const SetRecoveryQuestionParams(questionId: 'street', answer: 'Melati'),
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.recoveryQuestionId, 'street');
    expect(repository.storedAnswer, 'Melati');
  });

  test('propagates a storage failure', () async {
    repository.shouldFail = true;

    final result = await useCase(
      const SetRecoveryQuestionParams(questionId: 'city', answer: 'Bandung'),
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}