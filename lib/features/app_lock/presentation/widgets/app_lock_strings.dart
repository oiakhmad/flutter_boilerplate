import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_message.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';

/// Maps the message **keys** produced by the App Lock use cases (plain
/// strings, so the domain stays Flutter-free) to localized copy, and
/// translates non-validation [Failure] subtypes the same way `ErrorView`
/// does. This is the seam between domain validation codes and
/// presentation-layer l10n for this feature.
///
/// [lockoutSeconds] feeds the `appLockTooManyAttempts` placeholder; callers
/// pass `AppLockController.lockoutSecondsRemaining`.
String localizeAppLockFailure(
  BuildContext context,
  Failure? failure, {
  int lockoutSeconds = 0,
}) {
  if (failure == null) return '';
  final l10n = context.l10n;

  if (failure is ValidationFailure) {
    if (failure.fieldErrors.isEmpty) return l10n.errorValidation;
    final key = failure.fieldErrors.values.first;
    return switch (key) {
      'appLockPinInvalid' => l10n.appLockPinInvalid,
      'appLockPinMismatch' => l10n.appLockPinMismatch,
      'appLockPinIncorrect' => l10n.appLockPinIncorrect,
      'appLockAlreadyEnabled' => l10n.appLockAlreadyEnabled,
      'appLockTooManyAttempts' => l10n.appLockTooManyAttempts(lockoutSeconds),
      'appLockAnswerRequired' => l10n.appLockAnswerRequired,
      'appLockAnswerIncorrect' => l10n.appLockAnswerIncorrect,
      'appLockQuestionInvalid' => l10n.appLockQuestionInvalid,
      _ => l10n.errorValidation,
    };
  }

  return switch (failure) {
    DatabaseFailure() => l10n.errorDatabase,
    ValidationFailure() => l10n.errorValidation,
    NetworkFailure() => l10n.errorDatabase,
    NotFoundFailure() => l10n.errorUnexpected,
    UnexpectedFailure() => l10n.errorUnexpected,
  };
}

/// Lockout-aware error text for the PIN pages/dialogs.
///
/// While the lockout window is active the countdown message wins over the
/// last per-attempt error, so the user always sees *why* verification is
/// blocked and for how long (the value refreshes every second on the Lock
/// page via its countdown timer). Otherwise this is just
/// [localizeAppLockFailure].
String appLockErrorText(BuildContext context, AppLockController controller) {
  if (controller.isInLockout) {
    return context.l10n
        .appLockTooManyAttempts(controller.lockoutSecondsRemaining);
  }
  return localizeAppLockFailure(
    context,
    controller.failure,
    lockoutSeconds: controller.lockoutSecondsRemaining,
  );
}

/// Posts the standard notification for reaching the PIN attempt limit.
///
/// Called after a failed PIN submission; shows an [AppMessage] **warning**
/// (a lockout is a temporary restriction, not a hard error - so warning
/// rather than error is the right severity flag) carrying the remaining
/// cooldown. No-op while the lockout is not active, so attempts below the
/// limit keep only their inline "Incorrect PIN" feedback and never spam
/// the user with snackbars.
void notifyLockout(BuildContext context, AppLockController controller) {
  if (!controller.isInLockout) return;
  AppMessage.showWarning(
    context,
    context.l10n.appLockTooManyAttempts(controller.lockoutSecondsRemaining),
  );
}

/// Maps a stored recovery-question id (locale-independent, see
/// [AppLockConstants.recoveryQuestionIds]) to its localized text; `null`
/// yields the "not configured" status copy.
String recoveryQuestionLabel(BuildContext context, String? questionId) {
  final l10n = context.l10n;
  if (questionId == null) return l10n.appLockRecoveryNotSet;
  return switch (questionId) {
    'pet' => l10n.appLockQuestionPet,
    'city' => l10n.appLockQuestionCity,
    'teacher' => l10n.appLockQuestionTeacher,
    'vehicle' => l10n.appLockQuestionVehicle,
    'street' => l10n.appLockQuestionStreet,
    _ => l10n.appLockQuestionInvalid,
  };
}