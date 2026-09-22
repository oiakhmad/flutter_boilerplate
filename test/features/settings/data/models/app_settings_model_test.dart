import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/models/app_settings_model.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_primary_color.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake, matching the account-slice test convention: no
/// mocking framework, no database.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.stored);

  AppSettings stored;
  int saveCalls = 0;
  bool shouldFail = false;

  @override
  Future<Result<AppSettings>> getSettings() async =>
      Result.success(stored);

  @override
  Future<Result<void>> saveSettings(AppSettings settings) async {
    saveCalls++;
    if (shouldFail) {
      return const Result.failure(DatabaseFailure('disk full'));
    }
    stored = settings;
    return const Result.success(null);
  }
}

void main() {
  group('AppSettingsModel primary color persistence', () {
    test('round-trips a preset choice', () {
      const model = AppSettingsModel(
        themeMode: AppThemeMode.light,
        languageCode: 'en',
        primaryColor: PrimaryColorPreference.preset(
          PrimaryColorPreset.teal,
        ),
      );

      final decoded = AppSettingsModel.fromMap('app_settings', model.toMap());

      expect(decoded.primaryColor.preset, PrimaryColorPreset.teal);
      expect(decoded.primaryColor.customArgb, isNull);
    });

    test('round-trips a custom ARGB value', () {
      const model = AppSettingsModel(
        themeMode: AppThemeMode.dark,
        languageCode: 'id',
        primaryColor: PrimaryColorPreference.custom(0xFF123456),
      );

      final decoded = AppSettingsModel.fromMap('app_settings', model.toMap());

      expect(decoded.primaryColor.customArgb, 0xFF123456);
      expect(decoded.primaryColor.isCustom, isTrue);
    });

    test('falls back to default on missing keys', () {
      final decoded = AppSettingsModel.fromMap('app_settings', const {
        'themeMode': 'light',
        'languageCode': 'en',
      });

      expect(
        decoded.primaryColor,
        const PrimaryColorPreference.defaultPreset(),
      );
    });

    test('falls back to default on unknown preset name', () {
      final decoded = AppSettingsModel.fromMap('app_settings', const {
        'themeMode': 'light',
        'languageCode': 'en',
        'primaryColorPreset': 'chartreuse',
      });

      expect(
        decoded.primaryColor,
        const PrimaryColorPreference.defaultPreset(),
      );
    });

    test('falls back to default on corrupt value types', () {
      final decoded = AppSettingsModel.fromMap('app_settings', const {
        'themeMode': 'light',
        'languageCode': 'en',
        'primaryColorPreset': 42,
        'primaryColorArgb': 'not-a-color',
      });

      expect(
        decoded.primaryColor,
        const PrimaryColorPreference.defaultPreset(),
      );
    });

    test('prefers a valid custom ARGB over a preset', () {
      final decoded = AppSettingsModel.fromMap('app_settings', const {
        'themeMode': 'light',
        'languageCode': 'en',
        'primaryColorPreset': 'red',
        'primaryColorArgb': 0xFFABCDEF,
      });

      expect(decoded.primaryColor.customArgb, 0xFFABCDEF);
    });
  });

  group('UpdatePrimaryColorUseCase', () {
    late _FakeSettingsRepository repository;
    late UpdatePrimaryColorUseCase useCase;

    setUp(() {
      repository = _FakeSettingsRepository(AppSettings.initial());
      useCase = UpdatePrimaryColorUseCase(repository);
    });

    test('saves and returns the updated settings', () async {
      final result = await useCase(
        AppSettings.initial(),
        const PrimaryColorPreference.preset(PrimaryColorPreset.red),
      );

      expect(result.isSuccess, isTrue);
      expect(
        result.valueOrNull!.primaryColor.preset,
        PrimaryColorPreset.red,
      );
      expect(repository.saveCalls, 1);
      expect(repository.stored.primaryColor.preset, PrimaryColorPreset.red);
    });

    test('propagates a repository failure without updating', () async {
      repository.shouldFail = true;

      final result = await useCase(
        AppSettings.initial(),
        const PrimaryColorPreference.custom(0xFF123456),
      );

      expect(result.failureOrNull, isA<DatabaseFailure>());
      expect(repository.saveCalls, 1);
      expect(
        repository.stored.primaryColor,
        const PrimaryColorPreference.defaultPreset(),
      );
    });
  });
}
