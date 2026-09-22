import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/core/utils/validators.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Verifies **only** the recovery answer - the first step of the
/// forgot-PIN flow, so the user learns whether their answer is right
/// before being asked to choose a new PIN. The final submission goes
/// through [RecoverPinUseCase], which re-verifies everything atomically;
/// this use case never touches the PIN.
///
/// Business rules: the answer must be non-blank
/// (`appLockAnswerRequired`) and match the stored one
/// (`appLockAnswerIncorrect`). A missing stored answer propagates as
/// [NotFoundFailure] (recovery was never configured).
class VerifyRecoveryAnswerUseCase {
  const VerifyRecoveryAnswerUseCase(this._repository);

  final AppLockRepository _repository;

  Future<Result<void>> call(String answer) async {
    if (!Validators.isNotBlank(answer)) {
      return const Result.failure(
        ValidationFailure({'answer': 'appLockAnswerRequired'}),
      );
    }

    final verified = await _repository.verifyRecoveryAnswer(answer.trim());
    if (verified.isFailure) return Result.failure(verified.failureOrNull!);

    if (!verified.valueOrNull!) {
      return const Result.failure(
        ValidationFailure({'answer': 'appLockAnswerIncorrect'}),
      );
    }
    return const Result.success(null);
  }
}