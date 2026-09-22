import 'package:flutter/widgets.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/change_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/disable_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/enable_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/recover_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/set_recovery_question.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_recovery_answer.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
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
  Future<Result<AppLockConfig>> saveConfig(AppLockConfig config) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedConfig = config;
    return Result.success(config);
  }

  @override
  Future<Result<void>> savePin(String pin) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedPin = pin;
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> verifyPin(String pin) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    if (storedPin == null) {
      return const Result.failure(NotFoundFailure('PIN is not set'));
    }
    return Result.success(storedPin == pin);
  }

  @override
  Future<Result<void>> clearPin() async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedPin = null;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> saveRecoveryAnswer(String answer) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    storedAnswer = answer;
    return const Result.success(null);
  }

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

AppLockController _controller(_FakeAppLockRepository repository) {
  return AppLockController(
    getConfig: GetAppLockConfigUseCase(repository),
    enablePin: EnablePinUseCase(repository),
    disablePin: DisablePinUseCase(repository),
    verifyPin: VerifyPinUseCase(repository),
    verifyRecoveryAnswer: VerifyRecoveryAnswerUseCase(repository),
    changePin: ChangePinUseCase(repository),
    setRecoveryQuestion: SetRecoveryQuestionUseCase(repository),
    recoverPin: RecoverPinUseCase(repository),
  );
}

void main() {
  // The controller registers itself as a WidgetsBindingObserver in load().
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAppLockRepository repository;
  late AppLockController controller;

  setUp(() {
    repository = _FakeAppLockRepository();
    controller = _controller(repository);
  });

  tearDown(() => controller.dispose());

  test('load resolves ready state and leaves the lock off by default',
      () async {
    await controller.load();

    expect(controller.status, AppLockStatus.ready);
    expect(controller.config, AppLockConfig.initial());
    expect(controller.isLocked, isFalse);
  });

  test('load engages the lock when it was left enabled', () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '123456';

    await controller.load();

    expect(controller.status, AppLockStatus.ready);
    expect(controller.isLocked, isTrue,
        reason: 'a locked install must open onto the Lock Screen');
  });

  test('load surfaces a storage failure as a retryable error state',
      () async {
    repository.shouldFail = true;

    await controller.load();

    expect(controller.status, AppLockStatus.error);
    expect(controller.failure, isA<DatabaseFailure>());
    expect(controller.isLocked, isFalse,
        reason: 'availability fallback, like SettingsController.load');
  });

  test('enablePin updates the config so lockNow() can engage the lock',
      () async {
    await controller.load();
    final ok = await controller.enablePin('123456', '123456');

    expect(ok, isTrue);
    expect(controller.config.isEnabled, isTrue);
    expect(controller.isLocked, isFalse,
        reason: 'enabling does not lock the current session');

    controller.lockNow();
    expect(controller.isLocked, isTrue);
  });

  test('a background lifecycle transition engages the lock when enabled',
      () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '123456';
    await controller.load();
    expect(controller.isLocked, isTrue);

    // Simulate: unlock, then send to background and back.
    await controller.unlock('123456');
    expect(controller.isLocked, isFalse);

    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.isLocked, isFalse);

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(controller.isLocked, isTrue);
  });

  test('a background lifecycle transition never locks a disabled install',
      () async {
    await controller.load();

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);

    expect(controller.isLocked, isFalse);
  });

  test('unlock keeps the lock and reports the failure on a wrong PIN',
      () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '123456';
    await controller.load();

    final ok = await controller.unlock('999999');

    expect(ok, isFalse);
    expect(controller.isLocked, isTrue);
    final failure = controller.failure as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockPinIncorrect');
    expect(repository.storedConfig.failedAttempts, 1);
  });

  test('unlock clears the lock on the correct PIN', () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '123456';
    await controller.load();

    final ok = await controller.unlock('123456');

    expect(ok, isTrue);
    expect(controller.isLocked, isFalse);
    expect(controller.failure, isNull);
    expect(controller.isBusy, isFalse);
  });

  test('verifyCurrentPin never disengages an active lock', () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '123456';
    await controller.load();

    final ok = await controller.verifyCurrentPin('123456');

    expect(ok, isTrue);
    expect(controller.isLocked, isTrue,
        reason: 'change-PIN verification must not unlock the app');
  });

  test('disablePin turns the lock off and drops the PIN', () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '123456';
    await controller.load();

    final ok = await controller.disablePin('123456');

    expect(ok, isTrue);
    expect(controller.config.isEnabled, isFalse);
    expect(controller.isLocked, isFalse);
    expect(repository.storedPin, isNull);
  });

  test('changePin refuses a wrong old PIN', () async {
    repository.storedConfig =
        AppLockConfig.initial().copyWith(isEnabled: true);
    repository.storedPin = '123456';
    await controller.load();

    final ok = await controller.changePin('999999', '654321', '654321');

    expect(ok, isFalse);
    expect(repository.storedPin, '123456');
    final failure = controller.failure as ValidationFailure;
    expect(failure.fieldErrors['pin'], 'appLockPinIncorrect');
  });

  test('setRecoveryQuestion persists question and answer', () async {
    await controller.load();

    final ok = await controller.setRecoveryQuestion('city', 'Bandung');

    expect(ok, isTrue);
    expect(controller.config.recoveryQuestionId, 'city');
    expect(repository.storedAnswer, 'Bandung');
  });

  test('recoverPin applies the new PIN and unlocks', () async {
    repository.storedConfig = AppLockConfig.initial().copyWith(
      isEnabled: true,
      recoveryQuestionId: 'city',
    );
    repository.storedPin = '123456';
    repository.storedAnswer = 'Bandung';
    await controller.load();
    expect(controller.isLocked, isTrue);

    final ok = await controller.recoverPin('Bandung', '654321', '654321');

    expect(ok, isTrue);
    expect(controller.isLocked, isFalse);
    expect(repository.storedPin, '654321');
    expect(controller.config.isEnabled, isTrue);
  });

  test('lockout getters reflect the active window', () async {
    final until = DateTime.now().add(const Duration(seconds: 30));
    repository.storedConfig = AppLockConfig.initial().copyWith(
      isEnabled: true,
      failedAttempts: 5,
      lockoutUntil: until,
    );
    await controller.load();

    expect(controller.isInLockout, isTrue);
    expect(controller.lockoutSecondsRemaining, inInclusiveRange(1, 30));

    repository.storedConfig = AppLockConfig.initial();
    await controller.load();
    expect(controller.isInLockout, isFalse);
    expect(controller.lockoutSecondsRemaining, 0);
  });
}