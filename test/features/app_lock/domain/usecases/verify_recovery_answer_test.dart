import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_recovery_answer.dart';
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
  Future<Result<AppLockConfig>> saveConfig(AppLockConfig config) async =>
      throw UnimplementedError('not used by this test');

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
  late VerifyRecoveryAnswerUseCase useCase;

  setUp(() {
    repository = _FakeAppLockRepository()..storedAnswer = 'Bandung';
    useCase = VerifyRecoveryAnswerUseCase(repository);
  });

  test('rejects a blank answer before touching storage', () async {
    final result = await useCase('   ');

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['answer'], 'appLockAnswerRequired');
  });

  test('accepts the stored answer (trimmed comparison)', () async {
    final result = await useCase('  Bandung ');

    expect(result.isSuccess, isTrue);
  });

  test('rejects a wrong answer', () async {
    final result = await useCase('Jakarta');

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['answer'], 'appLockAnswerIncorrect');
  });

  test('reports a missing stored answer as NotFoundFailure', () async {
    repository.storedAnswer = null;

    final result = await useCase('Bandung');

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('propagates a storage failure', () async {
    repository.shouldFail = true;

    final result = await useCase('Bandung');

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}