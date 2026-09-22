import 'package:equatable/equatable.dart';

/// Domain-owned primary color presets.
///
/// Deliberately Flutter-free (`int` ARGB values only): the domain layer
/// defines its own vocabulary and the app theme layer maps a preset to a
/// `Color` seed at the boundary (see `AppSeedColors`).
///
/// Adding a new preset means adding one enum value + one entry in
/// `AppSeedColors` — domain, data, and UI components stay untouched.
enum PrimaryColorPreset {
  green,
  blue,
  brown,
  red,
  orange,
  purple,
  teal,
}

/// Domain-owned primary color preference.
///
/// Explicitly distinguishes the two selection kinds required by the spec:
///
/// - **Preset chosen** → stored as a [PrimaryColorPreset] identifier.
/// - **Custom color chosen** → stored as an exact ARGB `int` value.
///
/// Exactly one of [preset]/[customArgb] is set at any time.
class PrimaryColorPreference extends Equatable {
  const PrimaryColorPreference.preset(this.preset) : customArgb = null;

  const PrimaryColorPreference.custom(this.customArgb) : preset = null;

  const PrimaryColorPreference.defaultPreset()
      : preset = PrimaryColorPreset.blue,
        customArgb = null;

  final PrimaryColorPreset? preset;
  final int? customArgb;

  bool get isCustom => customArgb != null;

  @override
  List<Object?> get props => [preset, customArgb];
}
