import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Input for [EnablePinUseCase]: the chosen PIN plus its confirmation, as
/// collected by the two-step setup dialog.
class EnablePinParams {
  const EnablePinParams({required this.pin, required this.confirmPin});

  final String pin;
  final String confirmPin;
}

/// Turns the App Lock on and stores the 6-digit PIN in secure storage.
///
/// Business rules (all validated **before** any storage write, mirroring
/// `CreateAccountUseCase`):
///
/// - enabling twice is rejected (`appLockAlreadyEnabled`) - the switch only
///   ever offers this flow while the lock is off, and this guards the
///   use-case boundary too, so the PIN can never be silently overwritten
///   without verification;
/// - the PIN must be exactly [AppLockConstants.pinLength] digits
///   (`appLockPinInvalid`);
/// - the confirmation must match the PIN (`appLockPinMismatch`).
///
/// On success the config's `isEnabled` flag is flipped and the attempt
/// counter starts fresh.
class EnablePinUseCase {
  const EnablePinUseCase(this._repository);

  final AppLockRepository _repository;

  Future<Result<AppLockConfig>> call(EnablePinParams params) async {
    final configResult = await _repository.getConfig();
    if (configResult.isFailure) {
      return Result.failure(configResult.failureOrNull!);
    }
    final config = configResult.valueOrNull!;

    if (config.isEnabled) {
      return const Result.failure(
        ValidationFailure({'pin': 'appLockAlreadyEnabled'}),
      );
    }

    final fieldErrors = _validate(params.pin, params.confirmPin);
    if (fieldErrors.isNotEmpty) {
      return Result.failure(ValidationFailure(fieldErrors));
    }

    final savedPin = await _repository.savePin(params.pin);
    if (savedPin.isFailure) return Result.failure(savedPin.failureOrNull!);

    final updated = config.copyWith(
      isEnabled: true,
      failedAttempts: 0,
      lockoutUntil: null,
    );
    final savedConfig = await _repository.saveConfig(updated);
    if (savedConfig.isFailure) {
      return Result.failure(savedConfig.failureOrNull!);
    }
    return Result.success(updated);
  }

  Map<String, String> _validate(String pin, String confirmPin) {
    final errors = <String, String>{};
    if (!AppLockConstants.isValidPin(pin)) {
      errors['pin'] = 'appLockPinInvalid';
    }
    if (pin != confirmPin) {
      errors['confirmPin'] = 'appLockPinMismatch';
    }
    return errors;
  }
}