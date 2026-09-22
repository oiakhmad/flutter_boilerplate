import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/app_lock_strings.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/pin_input.dart';
import 'package:provider/provider.dart';

/// Three-step change-PIN dialog: old PIN (verified **before** the new one
/// may be chosen, per spec) -> new PIN -> confirm new PIN. Steps 1 and 2
/// only advance locally; the final submission calls
/// `AppLockController.changePin`, whose use case re-verifies the old PIN
/// and validates the new one atomically, so a wrong old PIN can never
/// result in a changed PIN even if a step were skipped.
class ChangePinDialog extends StatefulWidget {
  const ChangePinDialog({super.key});

  /// Opens the dialog; returns `true` only when the PIN was changed.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePinDialog(),
    );
    return result ?? false;
  }

  @override
  State<ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<ChangePinDialog> {
  int _step = 0; // 0: old PIN, 1: new PIN, 2: confirm new PIN.
  String _oldPin = '';
  String _newPin = '';
  String _entered = '';

  Future<void> _submit() async {
    if (_step == 0) {
      // Verify the old PIN first - only a correct PIN unlocks step 1.
      final controller = context.read<AppLockController>();
      final ok = await controller.verifyCurrentPin(_entered);
      if (!mounted) return;
      if (!ok) {
        notifyLockout(context, controller);
        return;
      }
      setState(() {
        _oldPin = _entered;
        _entered = '';
        _step = 1;
      });
      return;
    }
    if (_step == 1) {
      setState(() {
        _newPin = _entered;
        _entered = '';
        _step = 2;
      });
      return;
    }
    final controller = context.read<AppLockController>();
    final success = await controller.changePin(_oldPin, _newPin, _entered);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    // The re-verification of the old PIN can also hit the attempt limit.
    notifyLockout(context, controller);
  }

  String get _promptKey {
    final l10n = context.l10n;
    return switch (_step) {
      0 => l10n.appLockChangeOldPinPrompt,
      1 => l10n.appLockNewPinPrompt,
      _ => l10n.appLockConfirmNewPinPrompt,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AppLockController>();
    final error = appLockErrorText(context, controller);

    return AlertDialog(
      title: Text(l10n.appLockChangePinTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _promptKey,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Keyed by step so each step starts with an empty field.
          PinInput(
            key: ValueKey(_step),
            autofocus: true,
            enabled: !controller.isBusy,
            onChanged: (value) => setState(() => _entered = value),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: controller.isBusy
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed:
              _entered.length == 6 && !controller.isBusy ? _submit : null,
          child: controller.isBusy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_step == 2
                  ? l10n.appLockActionConfirm
                  : l10n.appLockActionNext),
        ),
      ],
    );
  }
}