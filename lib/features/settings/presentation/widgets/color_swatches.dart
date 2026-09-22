import 'package:flutter/material.dart';

/// A small curated palette of user-friendly custom seed colors shown in
/// the custom-color dialog. Raw `Color(...)` values live only here (plus
/// the central `AppSeedColors` registry) — never scattered across widgets.
const List<Color> customSwatches = [
  Color(0xFF2E7D32),
  Color(0xFF1565C0),
  Color(0xFF00838F),
  Color(0xFF00695C),
  Color(0xFF5D4037),
  Color(0xFF6A1B9A),
  Color(0xFFAD1457),
  Color(0xFFC62828),
  Color(0xFFE65100),
  Color(0xFFF9A825),
  Color(0xFF455A64),
  Color(0xFF212121),
];

/// Small filled circle for one swatch choice. The check icon always uses
/// the swatch's own seeded `onPrimary` so it stays readable.
class SwatchDot extends StatelessWidget {
  const SwatchDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                color: ColorScheme.fromSeed(seedColor: color).onPrimary,
                size: 20,
              )
            : null,
      ),
    );
  }
}
