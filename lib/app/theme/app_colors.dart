import 'package:flutter/material.dart';

/// Single seed-color source for both light and dark [ColorScheme]s.
///
/// Feature code must never reference a raw `Color(0xFF...)` - it should
/// pull colors from `Theme.of(context).colorScheme` (see
/// `context.colors` extension), which is generated from this seed.
abstract final class AppColors {
  static const Color seed = Color(0xFF3D5AFE);

  static ColorScheme light() => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      );

  static ColorScheme dark() => ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      );
}
