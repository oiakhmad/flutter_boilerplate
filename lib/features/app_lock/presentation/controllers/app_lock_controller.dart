import 'package:flutter/widgets.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/change_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/disable_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/enable_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/recover_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/set_recovery_question.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_recovery_answer.dart';

/// What the App Lock screens need to know about loading right now.
enum AppLockStatus {
  /// Nothing has been read yet.
  initial,

  /// Reading the stored config.
  loading,

  /// Config read successfully.
  ready,

  /// Reading the config failed; the Security page offers a retry.
  error,
}

/// Owns App Lock UI state and the lifecycle gate, and delegates every
/// business decision to use cases. Widgets read state via
/// [ChangeNotifier]/`context.watch`; they never touch the repository, data
/// sources, or storage directly.
///
/// Beyond state holding the controller:
///
/// - registers itself as a [WidgetsBindingObserver] during [load] and
///   re-locks on [AppLifecycleState.paused]/`hidden` while enabled - the
///   router reacts through [isLocked] because this controller is one of
///   its `refreshListenable`s;
/// - carries [returnLocation], written by the router guard before it
///   redirects to the Lock Screen, so unlocking returns the user to where
///   they were instead of always dropping them on Home.
///
/// PINs only ever live in a local variable handed to a use case; they are
/// never stored on this controller and never logged.
class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController({
    required GetAppLockConfigUseCase getConfig,
    required EnablePinUseCase enablePin,
    required DisablePinUseCase disablePin,
    required VerifyPinUseCase verifyPin,
    required VerifyRecoveryAnswerUseCase verifyRecoveryAnswer,
    required ChangePinUseCase changePin,
    required SetRecoveryQuestionUseCase setRecoveryQuestion,
    required RecoverPinUseCase recoverPin,
  })  : _getConfig = getConfig,
        _enablePin = enablePin,
        _disablePin = disablePin,
        _verifyPin = verifyPin,
        _verifyRecoveryAnswer = verifyRecoveryAnswer,
        _changePin = changePin,
        _setRecoveryQuestion = setRecoveryQuestion,
        _recoverPin = recoverPin;

  final GetAppLockConfigUseCase _getConfig;
  final EnablePinUseCase _enablePin;
  final DisablePinUseCase _disablePin;
  final VerifyPinUseCase _verifyPin;
  final VerifyRecoveryAnswerUseCase _verifyRecoveryAnswer;
  final ChangePinUseCase _changePin;
  final SetRecoveryQuestionUseCase _setRecoveryQuestion;
  final RecoverPinUseCase _recoverPin;

  AppLockStatus status = AppLockStatus.initial;
  AppLockConfig config = AppLockConfig.initial();

  /// The flag the router gates on: `true` while the Lock Screen must be
  /// shown. Starts `false`, follows [AppLockConfig.isEnabled] on load, and
  /// stays `true` until a successful verification.
  bool isLocked = false;

  /// `true` while a use-case call is in flight (buttons show a spinner and
  /// refuse duplicate submissions).
  bool isBusy = false;

  /// Failure of the most recent operation, or `null`. The presentation
  /// layer maps it to localized copy via `localizeAppLockFailure`.
  Failure? failure;

  /// Where the user was when the lock engaged, written by the router
  /// guard. `null` falls back to Home after unlocking.
  String? returnLocation;

  bool _observingLifecycle = false;

  /// Whether verification is currently blocked by the lockout window.
  bool get isInLockout {
    final until = config.lockoutUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Whole seconds left in the lockout window (0 when not locked out).
  int get lockoutSecondsRemaining {
    final until = config.lockoutUntil;
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Reads the persisted config and arms the lifecycle observer. Called
  /// once during startup (see `main.dart`) before the first frame, so a
  /// locked app opens straight onto the Lock Screen.
  ///
  /// A storage failure is reported as [AppLockStatus.error] instead of
  /// throwing; the config falls back to [AppLockConfig.initial] (lock off)
  /// so a corrupt record can never brick startup - the Security page shows
  /// the error with a retry.
  Future<void> load() async {
    status = AppLockStatus.loading;
    failure = null;
    notifyListeners();

    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }

    final result = await _getConfig();
    result.fold(
      (f) {
        failure = f;
        status = AppLockStatus.error;
        config = AppLockConfig.initial();
        isLocked = false;
      },
      (loaded) {
        config = loaded;
        isLocked = loaded.isEnabled;
        status = AppLockStatus.ready;
      },
    );
    notifyListeners();
  }

  /// Re-locks when the app leaves the foreground, so returning from the
  /// background (or the app switcher) always requires the PIN again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      lockNow();
    }
  }

  /// Engages the lock (no-op when the lock is disabled or already locked).
  /// Called by the lifecycle observer and directly by tests.
  void lockNow() {
    if (config.isEnabled && !isLocked) {
      isLocked = true;
      notifyListeners();
    }
  }

  /// Turns the lock on after creating a 6-digit PIN (setup dialog).
  Future<bool> enablePin(String pin, String confirmPin) async {
    _start();
    final result = await _enablePin(
      EnablePinParams(pin: pin, confirmPin: confirmPin),
    );
    return result.fold(
      _fail,
      (updated) {
        config = updated;
        _succeed();
        return true;
      },
    );
  }

  /// Verifies the PIN to unlock the app (Lock Screen submit). Success
  /// clears [isLocked]; the router then returns to [returnLocation].
  Future<bool> unlock(String pin) async {
    final success = await verifyCurrentPin(pin);
    if (success && !isLocked) return success;
    if (success) {
      isLocked = false;
      notifyListeners();
    }
    return success;
  }

  /// Verifies the current PIN **without** changing the lock state. Used by
  /// the change-PIN flow's first step ("old PIN must be correct before the
  /// new one may be chosen"); shares [VerifyPinUseCase] with unlocking, so
  /// the lockout window and attempt counter apply identically.
  Future<bool> verifyCurrentPin(String pin) async {
    _start();
    final result = await _verifyPin(pin);
    if (result.isFailure) {
      // The verifier persisted an attempt/lockout update - re-read it so
      // the lockout UI never renders stale values.
      await _refreshConfig();
      return _fail(result.failureOrNull!);
    }
    config = config.copyWith(failedAttempts: 0, lockoutUntil: null);
    _succeed();
    return true;
  }

  /// Verifies only the recovery answer (first step of the forgot-PIN
  /// flow), so the user learns whether the answer is right *before* being
  /// asked to choose a new PIN. [recoverPin] re-verifies everything
  /// atomically on the final submission.
  Future<bool> verifyRecoveryAnswer(String answer) async {
    _start();
    final result = await _verifyRecoveryAnswer(answer);
    return result.fold(_fail, (_) {
      _succeed();
      return true;
    });
  }

  /// Turns the lock off after verifying the current PIN (switch-off flow).
  Future<bool> disablePin(String pin) async {
    _start();
    final result = await _disablePin(pin);
    if (result.isFailure) {
      // A failed verification may have bumped the persisted attempt
      // counter - re-read so the in-memory config stays truthful.
      await _refreshConfig();
      return _fail(result.failureOrNull!);
    }
    config = result.valueOrNull!;
    isLocked = false;
    _succeed();
    return true;
  }

  /// Replaces the stored PIN; the old PIN must verify first (enforced in
  /// the use case).
  Future<bool> changePin(
    String oldPin,
    String newPin,
    String confirmNewPin,
  ) async {
    _start();
    final result = await _changePin(
      ChangePinParams(
        oldPin: oldPin,
        newPin: newPin,
        confirmNewPin: confirmNewPin,
      ),
    );
    if (result.isFailure) {
      // The verifier may have persisted an attempt/lockout update.
      await _refreshConfig();
      return _fail(result.failureOrNull!);
    }
    config = config.copyWith(failedAttempts: 0, lockoutUntil: null);
    _succeed();
    return true;
  }

  /// Saves/replaces the recovery security question and its answer.
  Future<bool> setRecoveryQuestion(String questionId, String answer) async {
    _start();
    final result = await _setRecoveryQuestion(
      SetRecoveryQuestionParams(questionId: questionId, answer: answer),
    );
    return result.fold(
      _fail,
      (updated) {
        config = updated;
        _succeed();
        return true;
      },
    );
  }

  /// Forgot-PIN flow: verifies the recovery answer and sets a new PIN in
  /// one atomic use case. Success unlocks the app (the account and all
  /// business data stay untouched).
  Future<bool> recoverPin(
    String answer,
    String newPin,
    String confirmNewPin,
  ) async {
    _start();
    final result = await _recoverPin(
      RecoverPinParams(
        answer: answer,
        newPin: newPin,
        confirmNewPin: confirmNewPin,
      ),
    );
    return result.fold(
      _fail,
      (updated) {
        config = updated;
        isLocked = false;
        _succeed();
        return true;
      },
    );
  }

  /// Re-reads the persisted config after an operation that may have
  /// mutated the attempt counter/lockout on disk. Storage failures are
  /// swallowed: the caller's original failure (or stale-but-valid config)
  /// is preferable to masking it with a second error.
  Future<void> _refreshConfig() async {
    final result = await _getConfig();
    if (result.isSuccess) {
      config = result.valueOrNull!;
    }
  }

  void _start() {
    isBusy = true;
    failure = null;
    notifyListeners();
  }

  bool _fail(Failure f) {
    failure = f;
    isBusy = false;
    notifyListeners();
    return false;
  }

  void _succeed() {
    isBusy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    super.dispose();
  }
}