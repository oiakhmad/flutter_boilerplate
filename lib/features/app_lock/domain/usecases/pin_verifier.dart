import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Shared PIN verification pipeline for every flow that must check the
/// stored PIN (unlock, turn off lock, change PIN).
///
/// Encapsulates the App Lock business rules that belong in the domain
/// layer and must never live in a widget:
///
/// - the lockout window blocks *any* verification while it is active
///   ([ValidationFailure] with the `appLockTooManyAttempts` message key);
///   once it expires the attempt budget is reset, so the user gets a fresh
///   set of tries;
/// - every failed attempt increments the persisted counter, and the final
///   allowed failure starts the lockout window;
/// - a successful verification resets the counter.
///
/// The message keys are plain strings (not localized text) so the domain
/// stays Flutter-free; the presentation layer maps them via
/// `localizeAppLockFailure`.
class PinVerifier {
  const PinVerifier(this._repository);

  final AppLockRepository _repository;

  /// Verifies [pin], maintaining the attempt counter and lockout window.
  ///
  /// Returns [Success] only when the stored PIN matches. Never logs or
  /// stores [pin] anywhere except through the repository's verification.
  Future<Result<void>> call(String pin) async {
    final configResult = await _repository.getConfig();
    if (configResult.isFailure) {
      return Result.failure(configResult.failureOrNull!);
    }
    var config = configResult.valueOrNull!;

    final now = DateTime.now();
    final lockoutUntil = config.lockoutUntil;
    if (lockoutUntil != null) {
      if (now.isBefore(lockoutUntil)) {
        return const Result.failure(
          ValidationFailure({'pin': 'appLockTooManyAttempts'}),
        );
      }
      // The window expired: give the user a fresh set of attempts. Done
      // before verifying so the reset survives even a failed try.
      config = config.copyWith(failedAttempts: 0, lockoutUntil: null);
      final cleared = await _repository.saveConfig(config);
      if (cleared.isFailure) return Result.failure(cleared.failureOrNull!);
    }

    final verified = await _repository.verifyPin(pin);
    if (verified.isFailure) return Result.failure(verified.failureOrNull!);

    if (verified.valueOrNull!) {
      if (config.failedAttempts != 0) {
        // Best-effort bookkeeping: a failed counter write must never mask
        // the successful verification the user just earned.
        await _repository.saveConfig(
          config.copyWith(failedAttempts: 0, lockoutUntil: null),
        );
      }
      return const Result.success(null);
    }

    final attempts = config.failedAttempts + 1;
    final updated = config.copyWith(
      failedAttempts: attempts,
      lockoutUntil: attempts >= AppLockConstants.maxFailedAttempts
          ? now.add(AppLockConstants.lockoutDuration)
          : null,
    );
    // Same rationale as above: persist the throttle state, but still report
    // "incorrect PIN" even if that bookkeeping write fails.
    await _repository.saveConfig(updated);

    return const Result.failure(
      ValidationFailure({'pin': 'appLockPinIncorrect'}),
    );
  }
}