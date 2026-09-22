import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Input for [RecoverPinUseCase]: the full "forgot PIN" submission.
///
/// The presentation flow collects the answer first (only reachable while
/// the recovery question is configured), then a new PIN and its
/// confirmation, and submits them together so every rule runs atomically
/// in this one use case.
class RecoverPinParams {
  const RecoverPinParams({
    required this.answer,
    required this.newPin,
    required this.confirmNewPin,
  });

  final String answer;
  final String newPin;
  final String confirmNewPin;
}

/// Resets the PIN after a successful recovery-question answer.
///
/// Business rules, in order:
///
/// 1. the new PIN must be exactly [AppLockConstants.pinLength] digits and
///    its confirmation must match - checked first so malformed input never
///    reaches the vault;
/// 2. the answer must match the stored recovery answer
///    (`appLockAnswerIncorrect` on mismatch).
///
/// On success the new PIN replaces the old one, the failed-attempt
/// counter/lockout are cleared, and the lock stays enabled. **Only the
/// lock's own secrets are touched** - the account and all business data
/// are never read or modified by this flow.
class RecoverPinUseCase {
  const RecoverPinUseCase(this._repository);

  final AppLockRepository _repository;

  Future<Result<AppLockConfig>> call(RecoverPinParams params) async {
    final fieldErrors = <String, String>{};
    if (!AppLockConstants.isValidPin(params.newPin)) {
      fieldErrors['newPin'] = 'appLockPinInvalid';
    }
    if (params.newPin != params.confirmNewPin) {
      fieldErrors['confirmNewPin'] = 'appLockPinMismatch';
    }
    if (fieldErrors.isNotEmpty) {
      return Result.failure(ValidationFailure(fieldErrors));
    }

    final verified = await _repository.verifyRecoveryAnswer(
      params.answer.trim(),
    );
    if (verified.isFailure) return Result.failure(verified.failureOrNull!);
    if (!verified.valueOrNull!) {
      return const Result.failure(
        ValidationFailure({'answer': 'appLockAnswerIncorrect'}),
      );
    }

    final savedPin = await _repository.savePin(params.newPin);
    if (savedPin.isFailure) return Result.failure(savedPin.failureOrNull!);

    final configResult = await _repository.getConfig();
    if (configResult.isFailure) {
      return Result.failure(configResult.failureOrNull!);
    }

    final updated = configResult.valueOrNull!.copyWith(
      failedAttempts: 0,
      lockoutUntil: null,
    );
    final savedConfig = await _repository.saveConfig(updated);
    if (savedConfig.isFailure) {
      return Result.failure(savedConfig.failureOrNull!);
    }
    return Result.success(updated);
  }
}