import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/widgets/color_swatches.dart';

/// Opens the custom-color picker dialog. Returns the chosen color, or
/// `null` when the user cancels.
Future<Color?> showCustomColorPicker(
  BuildContext context, {
  required Color initialColor,
}) {
  return showDialog<Color>(
    context: context,
    builder: (_) => CustomColorDialog(initialColor: initialColor),
  );
}

/// Dialog content is public (not `_`-private) so the slider state can be
/// covered by a widget test without pumping the whole settings page.
class CustomColorDialog extends StatefulWidget {
  const CustomColorDialog({super.key, required this.initialColor});

  final Color initialColor;

  @override
  State<CustomColorDialog> createState() => CustomColorDialogState();
}

class CustomColorDialogState extends State<CustomColorDialog> {
  late double hue;
  late double saturation;
  late double lightness;

  @override
  void initState() {
    super.initState();
    final hsl = HSLColor.fromColor(widget.initialColor);
    hue = hsl.hue;
    saturation = hsl.saturation.clamp(0.35, 1.0);
    lightness = hsl.lightness.clamp(0.3, 0.7);
  }

  Color get selected =>
      HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();

  void selectSwatch(Color swatch) {
    final hsl = HSLColor.fromColor(swatch);
    setState(() {
      hue = hsl.hue;
      saturation = hsl.saturation.clamp(0.35, 1.0);
      lightness = hsl.lightness.clamp(0.3, 0.7);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final previewScheme = ColorScheme.fromSeed(
      seedColor: selected,
      brightness: Theme.of(context).brightness,
    );

    return AlertDialog(
      title: Text(l10n.settingsPrimaryColorChooseTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: selected,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${(selected.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                style: TextStyle(
                  color: previewScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final swatch in customSwatches)
                  SwatchDot(
                    color: swatch,
                    selected: swatch.toARGB32() == selected.toARGB32(),
                    onTap: () => selectSwatch(swatch),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SliderRow(
              label: 'H',
              value: hue,
              min: 0,
              max: 360,
              activeColor: selected,
              onChanged: (v) => setState(() => hue = v),
            ),
            SliderRow(
              label: 'S',
              value: saturation,
              min: 0.35,
              max: 1,
              activeColor: selected,
              onChanged: (v) => setState(() => saturation = v),
            ),
            SliderRow(
              label: 'L',
              value: lightness,
              min: 0.3,
              max: 0.7,
              activeColor: selected,
              onChanged: (v) => setState(() => lightness = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.removeAccountCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(selected),
          child: Text(l10n.settingsPrimaryColorUseColor),
        ),
      ],
    );
  }
}

class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label, style: context.textStyles.labelLarge),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
