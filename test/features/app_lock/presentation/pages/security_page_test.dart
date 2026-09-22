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
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/pages/security_page.dart';
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

/// Builds the page the way `main()` + `app.dart` wire it: config loaded,
/// controller exposed through a provider, l10n delegates present.
Future<AppLockController> _pumpSecurity(
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
        home: SecurityPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

/// Lets a success SnackBar show and fully dismiss (its 3s duration) so no
/// timer is left pending when the test ends.
Future<void> _settleSuccessMessage(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

ListTile _changePinTile(WidgetTester tester) {
  return tester.widget<ListTile>(
    find.ancestor(
      of: find.text('Change 6-Digit PIN'),
      matching: find.byType(ListTile),
    ),
  );
}

void main() {
  testWidgets(
      'inactive state: PIN status off, recovery not set, change menu disabled',
      (tester) async {
    await _pumpSecurity(tester, _FakeAppLockRepository());

    expect(find.text('6-Digit PIN Lock'), findsOneWidget);
    expect(find.text('PIN not active'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Not set (Tap to set)'), findsOneWidget);
    expect(_changePinTile(tester).enabled, isFalse,
        reason: 'change PIN is only usable while the lock is active');
  });

  testWidgets(
      'enabling asks for a PIN and its confirmation, then reports active',
      (tester) async {
    final repository = _FakeAppLockRepository();
    await _pumpSecurity(tester, repository);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Create PIN'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm PIN'), findsOneWidget);

    // A mismatching confirmation is rejected and keeps the dialog open.
    await tester.enterText(find.byType(TextField), '654321');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('PINs do not match'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    // The matching confirmation enables the lock.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('PIN active'), findsOneWidget);
    expect(_changePinTile(tester).enabled, isTrue);
    expect(repository.storedPin, '123456');

    await _settleSuccessMessage(tester);
  });

  testWidgets('disabling verifies the current PIN first', (tester) async {
    final repository = _FakeAppLockRepository()
      ..storedConfig = AppLockConfig.initial().copyWith(isEnabled: true)
      ..storedPin = '123456';
    await _pumpSecurity(tester, repository);

    expect(find.text('PIN active'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Turn off app lock?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('Incorrect PIN'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(repository.storedConfig.isEnabled, isTrue);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('PIN not active'), findsOneWidget);
    expect(repository.storedPin, isNull);
    expect(repository.storedConfig.isEnabled, isFalse);

    await _settleSuccessMessage(tester);
  });

  testWidgets('the recovery question can be configured from the page',
      (tester) async {
    final repository = _FakeAppLockRepository();
    await _pumpSecurity(tester, repository);

    await tester.tap(find.text('Recovery Security Question'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bandung');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Configured (Tap to change)'), findsOneWidget);
    expect(repository.storedAnswer, 'Bandung');
    expect(repository.storedConfig.recoveryQuestionId, 'pet',
        reason: 'the first preset is preselected by default');

    await _settleSuccessMessage(tester);
  });

  testWidgets(
      'disabling posts an AppMessage warning at the attempt limit',
      (tester) async {
    final repository = _FakeAppLockRepository()
      ..storedConfig = AppLockConfig.initial().copyWith(isEnabled: true)
      ..storedPin = '123456';
    await _pumpSecurity(tester, repository);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Turn off app lock?'), findsOneWidget);

    for (var i = 0; i < AppLockConstants.maxFailedAttempts; i++) {
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'the dialog stays open on every failed attempt');
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.storedConfig.lockoutUntil, isNotNull,
        reason: 'the attempt budget is exhausted');
    expect(find.byType(SnackBar), findsOneWidget,
        reason: 'AppMessage warning is posted at the limit');
    expect(
      find.textContaining('Too many attempts'),
      findsAtLeastNWidgets(1),
    );
    expect(repository.storedConfig.isEnabled, isTrue,
        reason: 'the lock was never turned off');

    // Clear the SnackBar timer before the test ends (there is no Lock
    // page countdown timer here, so pumpAndSettle is safe afterwards).
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}