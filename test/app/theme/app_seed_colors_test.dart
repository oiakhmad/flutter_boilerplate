import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_colors.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSeedColors.resolve', () {
    test('resolves every preset to its registered seed', () {
      for (final preset in PrimaryColorPreset.values) {
        final seed = AppSeedColors.resolve(
          PrimaryColorPreference.preset(preset),
        );

        expect(seed, AppSeedColors.presets[preset]);
      }
    });

    test('resolves a custom ARGB value exactly', () {
      const argb = 0xFF123456;

      final seed = AppSeedColors.resolve(
        const PrimaryColorPreference.custom(argb),
      );

      expect(seed, const Color(argb));
    });

    test('falls back to default seed for an absent preset', () {
      // Every current preset resolves to its own seed; an unknown preset
      // (e.g. removed in a future version) can never be constructed, and
      // the model layer maps such stored names to the default preset
      // before resolution (covered in app_settings_model_test).
      expect(AppSeedColors.presets.length, PrimaryColorPreset.values.length);
      expect(
        AppSeedColors.resolve(
          const PrimaryColorPreference.defaultPreset(),
        ),
        AppSeedColors.presets[PrimaryColorPreset.blue],
      );
    });
  });

  group('ColorScheme.fromSeed integration', () {
    test('preset and custom seeds produce distinct schemes', () {
      final green = ColorScheme.fromSeed(
        seedColor: AppSeedColors.resolve(
          const PrimaryColorPreference.preset(PrimaryColorPreset.green),
        ),
      );
      final custom = ColorScheme.fromSeed(
        seedColor: AppSeedColors.resolve(
          const PrimaryColorPreference.custom(0xFF123456),
        ),
      );

      expect(green.primary, isNot(custom.primary));
    });

    test('dark scheme differs in brightness but shares seed hue family', () {
      final light = ColorScheme.fromSeed(
        seedColor: AppSeedColors.resolve(
          const PrimaryColorPreference.preset(PrimaryColorPreset.teal),
        ),
        brightness: Brightness.light,
      );
      final dark = ColorScheme.fromSeed(
        seedColor: AppSeedColors.resolve(
          const PrimaryColorPreference.preset(PrimaryColorPreset.teal),
        ),
        brightness: Brightness.dark,
      );

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.primary, isNot(dark.primary));
    });
  });
}
