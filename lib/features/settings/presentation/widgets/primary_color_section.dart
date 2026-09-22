import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_colors.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/widgets/color_swatches.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/widgets/custom_color_picker.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

/// "Primary color" section for the Settings page: 7 preset swatches plus
/// a custom-color entry. Everything is driven by `SettingsController` —
/// this widget holds no color state of its own.
///
/// - Tapping a preset persists its identifier via
///   `setPrimaryColorPreset` (the whole `ColorScheme` regenerates from
///   that seed; no restart needed).
/// - Tapping "Custom" opens [showCustomColorPicker]; confirming persists
///   the exact ARGB via `setCustomPrimaryColor`.
/// - The custom tile shows a checkmark while a custom value is active and
///   previews the currently stored custom color.
class PrimaryColorSection extends StatelessWidget {
  const PrimaryColorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<SettingsController>();
    final preference = controller.settings.primaryColor;
    final activeCustom = preference.customArgb != null
        ? Color(preference.customArgb!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            l10n.settingsPrimaryColorCustomHint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final preset in PrimaryColorPreset.values)
                _PresetDot(
                  key: ValueKey('preset_${preset.name}'),
                  preset: preset,
                  selected:
                      !preference.isCustom && preference.preset == preset,
                  onTap: () => context
                      .read<SettingsController>()
                      .setPrimaryColorPreset(preset),
                ),
              _CustomDot(
                key: const ValueKey('preset_custom'),
                activeCustom: activeCustom,
                onTap: () => _pickCustom(context, activeCustom),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustom(BuildContext context, Color? activeCustom) async {
    final chosen = await showCustomColorPicker(
      context,
      initialColor: activeCustom ?? AppSeedColors.defaultSeed,
    );
    if (chosen == null || !context.mounted) return;
    await context.read<SettingsController>().setCustomPrimaryColor(chosen);
  }
}

class _PresetDot extends StatelessWidget {
  const _PresetDot({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final PrimaryColorPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Preset ${preset.name}',
      child: SwatchDot(
        color: AppSeedColors.presets[preset]!,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

/// Custom entry tile: gradient-tinted circle with a "+" while no custom
/// value is active, or the stored custom color with a checkmark.
class _CustomDot extends StatelessWidget {
  const _CustomDot({super.key, required this.activeCustom, required this.onTap});

  final Color? activeCustom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    if (activeCustom != null) {
      return Tooltip(
        message: 'Custom color',
        child: SwatchDot(
          color: activeCustom!,
          selected: true,
          onTap: onTap,
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: 'Custom color',
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFD32F2F),
                Color(0xFFF9A825),
                Color(0xFF2E7D32),
                Color(0xFF1565C0),
                Color(0xFF6A1B9A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(Icons.add, color: scheme.onPrimary, size: 20),
        ),
      ),
    );
  }
}

/// Localized display names for the preset choices, used by the widget
/// test. Kept in presentation (not domain) because names are user-facing
/// copy; the colors themselves stay in [AppSeedColors].
String presetName(AppLocalizations l10n, PrimaryColorPreset preset) {
  return switch (preset) {
    PrimaryColorPreset.green => 'Green',
    PrimaryColorPreset.blue => 'Blue',
    PrimaryColorPreset.brown => 'Brown',
    PrimaryColorPreset.red => 'Red',
    PrimaryColorPreset.orange => 'Orange',
    PrimaryColorPreset.purple => 'Purple',
    PrimaryColorPreset.teal => 'Teal',
  };
}
