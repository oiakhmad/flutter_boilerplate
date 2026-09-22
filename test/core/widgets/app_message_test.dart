import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_message.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a minimal app hosting a trigger button. Tapping the button calls
/// `show(context, ...)` with the given type and an already-localized
/// message, mirroring the documented call-site pattern.
Future<void> _pumpMessageHarness(
  WidgetTester tester, {
  required AppMessageType type,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => AppMessage.show(
              context,
              // ignore: use_build_context_synchronously
              message: AppLocalizations.of(context).accountUpdateSuccess,
              type: type,
            ),
            child: const Text('trigger'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('trigger'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('success message uses primary container colors', (tester) async {
    await _pumpMessageHarness(tester, type: AppMessageType.success);

    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final scheme = Theme.of(
      tester.element(find.byType(SnackBar)),
    ).colorScheme;
    expect(snackBar.backgroundColor, scheme.primaryContainer);
  });

  testWidgets('error message uses error container colors', (tester) async {
    await _pumpMessageHarness(tester, type: AppMessageType.error);

    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final scheme = Theme.of(
      tester.element(find.byType(SnackBar)),
    ).colorScheme;
    expect(snackBar.backgroundColor, scheme.errorContainer);
  });

  testWidgets('warning message uses tertiary container colors', (tester) async {
    await _pumpMessageHarness(tester, type: AppMessageType.warning);

    expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final scheme = Theme.of(
      tester.element(find.byType(SnackBar)),
    ).colorScheme;
    expect(snackBar.backgroundColor, scheme.tertiaryContainer);
  });

  testWidgets('info message uses secondary container colors', (tester) async {
    await _pumpMessageHarness(tester, type: AppMessageType.info);

    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final scheme = Theme.of(
      tester.element(find.byType(SnackBar)),
    ).colorScheme;
    expect(snackBar.backgroundColor, scheme.secondaryContainer);
  });

  testWidgets('top-level helpers stay compatible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSuccessMessage(
                context,
                // ignore: use_build_context_synchronously
                message: AppLocalizations.of(context).accountUpdateSuccess,
              ),
              child: const Text('trigger'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
