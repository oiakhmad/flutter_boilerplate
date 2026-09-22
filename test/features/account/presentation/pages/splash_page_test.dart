import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/create_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/splash_page.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAccountRepository implements AccountRepository {
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

/// Builds the splash screen with the same wiring `main()` performs: the
/// gate is resolved first, then the page is rendered with the controller
/// exposed through a provider (as `app/app.dart` does).
Future<SplashController> _pumpSplash(
  WidgetTester tester,
  _FakeAccountRepository repository,
) async {
  final controller = SplashController(
    getAccount: GetAccountUseCase(repository),
    createAccount: CreateAccountUseCase(repository),
  );
  await controller.load();

  await tester.pumpWidget(
    ChangeNotifierProvider<SplashController>.value(
      value: controller,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashPage(),
      ),
    ),
  );
  await tester.pump();

  return controller;
}

/// Taps Next and lets the (fake) storage round-trip finish.
Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('first run shows the Welcome form', (tester) async {
    await _pumpSplash(tester, _FakeAccountRepository());

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('an existing account never sees the name form', (tester) async {
    final repository = _FakeAccountRepository()
      ..stored = Account(
        id: 'current_account',
        name: 'Budi',
        email: '',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

    final controller = await _pumpSplash(tester, repository);

    expect(controller.status, SplashStatus.ready);
    expect(controller.hasAccount, isTrue);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('a blank name cannot continue and is validated', (tester) async {
    final repository = _FakeAccountRepository();
    final controller = await _pumpSplash(tester, repository);

    await _tapNext(tester);

    expect(find.text('Name is required'), findsOneWidget);
    expect(controller.hasAccount, isFalse);
    expect(repository.stored, isNull, reason: 'nothing is persisted');
  });

  testWidgets('a valid name is stored once and unlocks the app',
      (tester) async {
    final repository = _FakeAccountRepository();
    final controller = await _pumpSplash(tester, repository);

    await tester.enterText(find.byType(TextField), 'Budi');
    await _tapNext(tester);

    expect(controller.status, SplashStatus.ready);
    expect(controller.hasAccount, isTrue);
    expect(repository.stored?.name, 'Budi');
    expect(find.text('Name is required'), findsNothing);
  });

  testWidgets('a storage failure is surfaced instead of throwing',
      (tester) async {
    final controller = SplashController(
      getAccount: GetAccountUseCase(_FailingAccountRepository()),
      createAccount: CreateAccountUseCase(_FailingAccountRepository()),
    );
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<SplashController>.value(
        value: controller,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashPage(),
        ),
      ),
    );
    await tester.pump();

    expect(controller.status, SplashStatus.error);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _FailingAccountRepository implements AccountRepository {
  @override
  Future<Result<Account?>> getAccount() async =>
      const Result.failure(DatabaseFailure('storage unavailable'));

  @override
  Future<Result<void>> saveAccount(Account account) async =>
      const Result.failure(DatabaseFailure('storage unavailable'));

  @override
  Future<Result<void>> removeAccount() async =>
      const Result.failure(DatabaseFailure('storage unavailable'));
}
