import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/remove_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/save_account.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/edit_account_page.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeAccountRepository implements AccountRepository {
  Account? saved;

  @override
  Future<Result<Account?>> getAccount() async => Result.success(saved);

  @override
  Future<Result<void>> saveAccount(Account account) async {
    saved = account;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> removeAccount() async {
    saved = null;
    return const Result.success(null);
  }
}

Future<AccountController> _pumpEditPage(
  WidgetTester tester,
  _FakeAccountRepository repository,
) async {
  final controller = AccountController(
    getAccount: GetAccountUseCase(repository),
    saveAccount: SaveAccountUseCase(repository),
    removeAccount: RemoveAccountUseCase(repository),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<AccountController>.value(
      value: controller,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditAccountPage(),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('Update Account rejects security payloads without saving',
      (tester) async {
    final repository = _FakeAccountRepository();
    final controller = await _pumpEditPage(tester, repository);
    final nameField = find.byType(TextField).first;

    for (final payload in [
      "' OR '1'='1",
      '" OR "1"="1',
      '<script>alert(1)</script>',
      '<img src=x onerror=alert(1)>',
      '../../../../etc/passwd',
      r'${7*7}',
      r'{{7*7}}',
      '<!-- test -->',
    ]) {
      await tester.enterText(nameField, payload);
      await tester.enterText(find.byType(TextField).last, 'user@example.com');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(repository.saved, isNull, reason: 'invalid input is not stored');
      expect(find.text('Name contains characters that aren\'t allowed'),
          findsOneWidget);
      expect(controller.saveStatus, SaveStatus.error);
    }
  });

  testWidgets('Update Account accepts valid Unicode name and email characters',
      (tester) async {
    final repository = _FakeAccountRepository();
    final controller = await _pumpEditPage(tester, repository);

    await tester.enterText(
      find.byType(TextField).first,
      "  O'Connor  ",
    );
    await tester.enterText(
      find.byType(TextField).last,
      ' user+tag@example.com ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.saved?.name, "O'Connor");
    expect(repository.saved?.email, 'user+tag@example.com');
    expect(controller.saveStatus, SaveStatus.success);
  });

  testWidgets('Update Account displays a localized invalid email message',
      (tester) async {
    final repository = _FakeAccountRepository();
    await _pumpEditPage(tester, repository);

    await tester.enterText(find.byType(TextField).first, 'Valid Name');
    await tester.enterText(find.byType(TextField).last, 'not-an-email');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(repository.saved, isNull);
  });
}
