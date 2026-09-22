import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/pin_verifier.dart';

/// Turns the App Lock off.
///
/// Business rule: the current PIN must verify first (same [PinVerifier]
/// pipeline as unlocking, including the lockout window and attempt
/// counter). Only then is the stored PIN removed from secure storage and
/// the config's `isEnabled` flag cleared. On any failure the lock stays
/// exactly as it was.
///
/// The recovery question/answer are intentionally kept: they are an
/// independent setting the user configured explicitly, and clearing them
/// here would silently destroy the way back in after the lock is
/// re-enabled.
class DisablePinUseCase {
  DisablePinUseCase(AppLockRepository repository)
      : _repository = repository,
        _verifier = PinVerifier(repository);

  final AppLockRepository _repository;
  final PinVerifier _verifier;

  Future<Result<AppLockConfig>> call(String pin) async {
    final verified = await _verifier(pin);
    if (verified.isFailure) return Result.failure(verified.failureOrNull!);

    final cleared = await _repository.clearPin();
    if (cleared.isFailure) return Result.failure(cleared.failureOrNull!);

    // Re-read: the verifier may have just persisted an attempt-counter
    // reset we must not overwrite with a stale copy.
    final configResult = await _repository.getConfig();
    if (configResult.isFailure) {
      return Result.failure(configResult.failureOrNull!);
    }

    final updated = configResult.valueOrNull!.copyWith(
      isEnabled: false,
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