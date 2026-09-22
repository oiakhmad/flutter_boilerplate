import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/core/utils/validators.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Input for [SetRecoveryQuestionUseCase].
class SetRecoveryQuestionParams {
  const SetRecoveryQuestionParams({
    required this.questionId,
    required this.answer,
  });

  /// One of [AppLockConstants.recoveryQuestionIds].
  final String questionId;

  final String answer;
}

/// Configures (or replaces) the recovery security question used when the
/// user forgets their PIN.
///
/// Business rules (validated before any write):
///
/// - [SetRecoveryQuestionParams.questionId] must be one of the supported
///   preset ids (`appLockQuestionInvalid`);
/// - the answer must be non-blank (`appLockAnswerRequired`).
///
/// The answer itself goes to secure storage through the repository - it is
/// never written to Sembast; only the question id is persisted in the
/// config. This flow never touches the account or any business data.
class SetRecoveryQuestionUseCase {
  const SetRecoveryQuestionUseCase(this._repository);

  final AppLockRepository _repository;

  Future<Result<AppLockConfig>> call(
    SetRecoveryQuestionParams params,
  ) async {
    final fieldErrors = <String, String>{};
    if (!AppLockConstants.recoveryQuestionIds.contains(params.questionId)) {
      fieldErrors['questionId'] = 'appLockQuestionInvalid';
    }
    if (!Validators.isNotBlank(params.answer)) {
      fieldErrors['answer'] = 'appLockAnswerRequired';
    }
    if (fieldErrors.isNotEmpty) {
      return Result.failure(ValidationFailure(fieldErrors));
    }

    final savedAnswer = await _repository.saveRecoveryAnswer(
      params.answer.trim(),
    );
    if (savedAnswer.isFailure) {
      return Result.failure(savedAnswer.failureOrNull!);
    }

    final configResult = await _repository.getConfig();
    if (configResult.isFailure) {
      return Result.failure(configResult.failureOrNull!);
    }

    final updated = configResult.valueOrNull!
        .copyWith(recoveryQuestionId: params.questionId);
    final savedConfig = await _repository.saveConfig(updated);
    if (savedConfig.isFailure) {
      return Result.failure(savedConfig.failureOrNull!);
    }
    return Result.success(updated);
  }
}