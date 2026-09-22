import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/get_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_language.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_primary_color.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_theme_mode.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Hand-rolled fake repository: no mocking framework, no database.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.stored);

  AppSettings stored;
  int presetCalls = 0;
  int customCalls = 0;

  @override
  Future<Result<AppSettings>> getSettings() async =>
      Result.success(stored);

  @override
  Future<Result<void>> saveSettings(AppSettings settings) async {
    if (settings.primaryColor.isCustom) {
      customCalls++;
    } else {
      presetCalls++;
    }
    stored = settings;
    return const Result.success(null);
  }
}

SettingsController _controller(_FakeSettingsRepository repository) {
  return SettingsController(
    getSettings: GetSettingsUseCase(repository),
    updateThemeMode: UpdateThemeModeUseCase(repository),
    updateLanguage: UpdateLanguageUseCase(repository),
    updatePrimaryColor: UpdatePrimaryColorUseCase(repository),
  );
}

Future<void> _pumpSettings(
  WidgetTester tester,
  SettingsController controller,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsController>.value(
      value: controller,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('preset dots persist the preset and move selection',
      (tester) async {
    final repository =
        _FakeSettingsRepository(AppSettings.initial());
    final controller = _controller(repository);
    await _pumpSettings(tester, controller);

    expect(find.text('Primary color'), findsOneWidget);

    await tester.tap(find.byTooltip('Preset red'));
    await tester.pumpAndSettle();

    expect(repository.presetCalls, 1);
    expect(
      controller.settings.primaryColor.preset,
      PrimaryColorPreset.red,
    );
  });

  testWidgets('custom flow opens the picker and persists ARGB', (
    tester,
  ) async {
    final repository =
        _FakeSettingsRepository(AppSettings.initial());
    final controller = _controller(repository);
    await _pumpSettings(tester, controller);

    await tester.tap(find.byTooltip('Custom color'));
    await tester.pumpAndSettle();

    expect(find.text('Choose custom color'), findsOneWidget);

    await tester.tap(find.text('Use this color'));
    await tester.pumpAndSettle();

    expect(repository.customCalls, 1);
    expect(controller.settings.primaryColor.isCustom, isTrue);
    expect(controller.settings.primaryColor.customArgb, isNotNull);
  });
}
