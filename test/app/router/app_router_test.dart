import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/di/injector.dart';
import 'package:flutter_clean_boilerplate/app/router/app_router.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/create_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/splash_page.dart';
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

void main() {
  late _InMemoryAccountRepository repository;
  late SplashController controller;

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
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SplashController>.value(
        value: controller,
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
}
