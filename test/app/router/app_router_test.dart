import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/di/injector.dart';
import 'package:flutter_clean_boilerplate/app/router/app_router.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/create_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/splash_page.dart';
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
import 'package:flutter_clean_boilerplate/features/home/presentation/pages/home_page.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _InMemoryAccountRepository implements AccountRepository {
  Account? stored;

  @override
  Future<Result<Account?>> getAccount() async => Result.success(stored);

  @override
  Future<Result<void>> saveAccount(Account account) async {
    stored = account;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> removeAccount() async {
    stored = null;
    return const Result.success(null);
  }
}

/// Hand-rolled App Lock fake for the router gate: config + PIN only, the
/// other secret operations are never reached by these tests.
class _FakeAppLockRepository implements AppLockRepository {
  AppLockConfig storedConfig = AppLockConfig.initial();
  String? storedPin;

  @override
  Future<Result<AppLockConfig>> getConfig() async =>
      Result.success(storedConfig);

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
  Future<Result<void>> clearPin() async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<void>> saveRecoveryAnswer(String answer) async =>
      throw UnimplementedError('not used by this test');

  @override
  Future<Result<bool>> verifyRecoveryAnswer(String answer) async =>
      throw UnimplementedError('not used by this test');
}

void main() {
  late _InMemoryAccountRepository repository;
  late SplashController controller;
  late AppLockController appLockController;
  late _FakeAppLockRepository appLockRepository;

  setUpAll(() {
    repository = _InMemoryAccountRepository();
    controller = SplashController(
      getAccount: GetAccountUseCase(repository),
      createAccount: CreateAccountUseCase(repository),
    );
    // The real router reads the gate from the composition root, so the
    // controller has to be registered before `appRouter` is first read (it is
    // a lazily created global, exactly as in `main.dart`).
    getIt.registerLazySingleton<SplashController>(() => controller);

    // The router now gates on two singletons - register the App Lock one
    // with a lock-disabled fake, mirroring `setupDependencies()`.
    appLockRepository = _FakeAppLockRepository();
    appLockController = AppLockController(
      getConfig: GetAppLockConfigUseCase(appLockRepository),
      enablePin: EnablePinUseCase(appLockRepository),
      disablePin: DisablePinUseCase(appLockRepository),
      verifyPin: VerifyPinUseCase(appLockRepository),
      verifyRecoveryAnswer: VerifyRecoveryAnswerUseCase(appLockRepository),
      changePin: ChangePinUseCase(appLockRepository),
      setRecoveryQuestion: SetRecoveryQuestionUseCase(appLockRepository),
      recoverPin: RecoverPinUseCase(appLockRepository),
    );
    getIt.registerLazySingleton<AppLockController>(() => appLockController);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SplashController>.value(value: controller),
          ChangeNotifierProvider<AppLockController>.value(
            value: appLockController,
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// One test walks the whole gate against the app's real router, so the
  /// process-global `appRouter` (which remembers its location) is only ever
  /// created once per test file.
  testWidgets('first run shows splash once, then the app opens on Home',
      (tester) async {
    // 1. Brand-new device: `main()` resolves the gate, no account is found.
    repository.stored = null;
    await controller.load();
    expect(controller.hasAccount, isFalse);

    await pumpApp(tester);
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // 2. Name + Next creates the account; the router - not the page - moves
    //    the user to Home, because the controller is its `refreshListenable`.
    await tester.enterText(find.byType(TextField), 'Budi');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(repository.stored?.name, 'Budi');
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);

    // 3. Later launch (or any navigation to /splash) with an account already
    //    stored: the form is skipped and Home is shown.
    await controller.load();
    expect(controller.hasAccount, isTrue);

    appRouter.go(AppRoutes.splash);
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  // Runs after the first gate walk (the router is a process-global that
  // remembers its location), so the app is sitting on /home with the lock
  // still disabled at this point.
  testWidgets(
      'app lock funnels to the Lock Screen on background and back after unlock',
      (tester) async {
    // Resolve the gate state before the first frame, as `main.dart` does.
    await appLockController.load();
    expect(appLockController.isLocked, isFalse);

    final enabled = await appLockController.enablePin('123456', '123456');
    expect(enabled, isTrue);
    expect(appLockController.isLocked, isFalse,
        reason: 'enabling alone must not lock the running session');

    // Mount the UI while still unlocked: the app sits on Home.
    await pumpApp(tester);
    expect(find.byType(HomePage), findsOneWidget);

    // Send the app to the background: the lifecycle observer engages the
    // lock and the router redirects before anything is shown again.
    appLockController.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(find.byType(LockPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    // Validation happens before access: a wrong PIN keeps the lock.
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.byType(LockPage), findsOneWidget);
    expect(find.text('Incorrect PIN'), findsOneWidget);

    // The correct PIN unlocks and returns to the remembered location.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.byType(LockPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(appLockController.isLocked, isFalse);
  });
}
