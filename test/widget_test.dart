import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/features/home/presentation/pages/home_page.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomePage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomePage(),
      ),
    );
    expect(find.byType(HomePage), findsOneWidget);
  });
}
