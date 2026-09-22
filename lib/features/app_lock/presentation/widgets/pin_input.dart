import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';

/// 6-digit PIN input: a row of six dots backed by a hidden numeric field.
///
/// Reuses the existing theme tokens only (`AppSpacing`, ambient
/// `ColorScheme`, `TextTheme`) - no new design system. The real input is a
/// transparent [TextField] stretched behind the dots, so taps anywhere on
/// the widget focus the keyboard while the entered digits are shown as
/// filled/empty circles (never as readable text).
///
/// The input is restricted to exactly [AppLockConstants.pinLength] ASCII
/// digits at the widget level for typing comfort only - the authoritative
/// validation lives in the use cases.
class PinInput extends StatefulWidget {
  const PinInput({
    super.key,
    required this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  /// Called on every keystroke with the raw digits entered so far.
  final ValueChanged<String> onChanged;

  final bool autofocus;
  final bool enabled;

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final length = AppLockConstants.pinLength;
    final entered = _controller.text.length;

    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The actual input: transparent, but full-size so the whole
          // area is tappable and the keyboard is numeric.
          Positioned.fill(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(length),
              ],
              onChanged: widget.onChanged,
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                counterText: '',
                hintText: '',
              ),
            ),
          ),
          // The visible dots; they never intercept taps (the field below
          // handles them).
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < length; i++)
                  Container(
                    width: AppSpacing.md,
                    height: AppSpacing.md,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < entered
                          ? colors.primary
                          : Colors.transparent,
                      border: i < entered
                          ? null
                          : Border.all(color: colors.outline, width: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}