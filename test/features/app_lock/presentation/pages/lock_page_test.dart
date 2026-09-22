import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
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
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/pages/lock_page.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Hand-rolled fake, matching the account/settings test convention: no
/// mocking framework, no database, no secure storage.
class _FakeAppLockRepository implements AppLockRepository {
  AppLockConfig storedConfig = AppLockConfig.initial();
  String? storedPin;
  String? storedAnswer;

  @override
  Future<Result<AppLockConfig>> getConfig() async => Result.success(storedConfig);

  @override
  Future<Result<AppLockConfig>> saveConfig(AppLockConfig config) async {
    storedConfig = config;
    return Result.success(config);
  }

  @override
  Future<Result<void>> savePin(String pin) async {
    storedPin = pin;
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> verifyPin(String pin) async {
    if (storedPin == null) {
      return const Result.failure(NotFoundFailure('PIN is not set'));
    }
    return Result.success(storedPin == pin);
  }

  @override
  Future<Result<void>> clearPin() async {
    storedPin = null;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> saveRecoveryAnswer(String answer) async {
    storedAnswer = answer;
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> verifyRecoveryAnswer(String answer) async {
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

/// A lock-enabled, PIN-armed repository - the state the Lock Screen is
/// shown in.
_FakeAppLockRepository _lockedRepository() {
  return _FakeAppLockRepository()
    ..storedConfig = AppLockConfig.initial().copyWith(
      isEnabled: true,
      recoveryQuestionId: 'city',
    )
    ..storedPin = '123456'
    ..storedAnswer = 'Bandung';
}

Future<AppLockController> _pumpLock(
  WidgetTester tester,
  _FakeAppLockRepository repository,
) async {
  final controller = _controller(repository);
  await controller.load();

  await tester.pumpWidget(
    ChangeNotifierProvider<AppLockController>.value(
      value: controller,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LockPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('shows the locked state with an initially disabled action',
      (tester) async {
    await _pumpLock(tester, _lockedRepository());

    expect(find.text('App locked'), findsOneWidget);
    expect(find.text('Enter your PIN to unlock the app.'), findsOneWidget);
    expect(find.text('Forgot PIN?'), findsOneWidget,
        reason: 'recovery is offered because a question is configured');

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Unlock'),
    );
    expect(button.onPressed, isNull,
        reason: 'six digits are required before submitting');
  });

  testWidgets('hides the recovery link while no question is configured',
      (tester) async {
    final repository = _lockedRepository()
      ..storedConfig = AppLockConfig.initial().copyWith(isEnabled: true)
      ..storedAnswer = null;
    await _pumpLock(tester, repository);

    expect(find.text('App locked'), findsOneWidget);
    expect(find.text('Forgot PIN?'), findsNothing);
  });

  testWidgets('rejects a wrong PIN, then accepts the correct one',
      (tester) async {
    final controller = await _pumpLock(tester, _lockedRepository());

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect PIN'), findsOneWidget);
    expect(controller.isLocked, isTrue,
        reason: 'validation happens before any access is granted');
    expect(controller.config.failedAttempts, 1);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(controller.isLocked, isFalse);
    expect(find.text('Incorrect PIN'), findsNothing);
    expect(controller.config.failedAttempts, 0);
  });

  testWidgets(
      'posts an AppMessage warning when the attempt limit is reached',
      (tester) async {
    final controller = await _pumpLock(tester, _lockedRepository());

    // Attempts below the limit: inline "Incorrect PIN" only - no
    // notification and no lockout yet.
    for (var i = 0; i < AppLockConstants.maxFailedAttempts - 1; i++) {
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.isInLockout, isFalse);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Incorrect PIN'), findsOneWidget);
    }

    // The final allowed failure starts the lockout: an AppMessage warning
    // posts the cooldown while the inline error switches to the countdown
    // message (severity flag: warning, not error - it is a temporary
    // restriction).
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.isInLockout, isTrue);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('Too many attempts'),
      findsAtLeastNWidgets(2),
      reason: 'both the AppMessage and the inline countdown show it',
    );
    expect(
      find.text('Incorrect PIN'),
      findsNothing,
      reason: 'the stale per-attempt error yields to the countdown',
    );

    // Dismiss the SnackBar cleanly. pumpAndSettle is deliberately avoided:
    // the Lock page keeps a 1s countdown Timer running for the whole
    // real-time lockout window and would keep it spinning forever.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}