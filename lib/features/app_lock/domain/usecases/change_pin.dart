import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/pin_verifier.dart';

/// Input for [ChangePinUseCase]: the three values of the change-PIN flow.
class ChangePinParams {
  const ChangePinParams({
    required this.oldPin,
    required this.newPin,
    required this.confirmNewPin,
  });

  final String oldPin;
  final String newPin;
  final String confirmNewPin;
}

/// Replaces the stored PIN.
///
/// Business rules, in order:
///
/// 1. the **old** PIN must verify first ([PinVerifier] - lockout and
///    attempt counter apply here too); if it is wrong nothing else runs
///    and the stored PIN is untouched;
/// 2. the new PIN must be exactly [AppLockConstants.pinLength] digits;
/// 3. the new PIN and its confirmation must match.
///
/// Only after all three pass is the new PIN written to secure storage.
class ChangePinUseCase {
  ChangePinUseCase(AppLockRepository repository)
      : _repository = repository,
        _verifier = PinVerifier(repository);

  final AppLockRepository _repository;
  final PinVerifier _verifier;

  Future<Result<void>> call(ChangePinParams params) async {
    // 1. Old PIN first - a wrong old PIN must block everything else.
    final verified = await _verifier(params.oldPin);
    if (verified.isFailure) return Result.failure(verified.failureOrNull!);

    // 2 + 3. New PIN shape and confirmation.
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

    final savedPin = await _repository.savePin(params.newPin);
    if (savedPin.isFailure) return Result.failure(savedPin.failureOrNull!);

    return const Result.success(null);
  }
}