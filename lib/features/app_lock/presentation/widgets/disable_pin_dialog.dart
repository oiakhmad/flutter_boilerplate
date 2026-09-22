import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/app_lock_strings.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/pin_input.dart';
import 'package:provider/provider.dart';

/// Single-step dialog that verifies the current PIN before the lock is
/// turned off (the switch-off flow). The PIN is handed straight to
/// `AppLockController.disablePin`, which verifies it, removes it from
/// secure storage and clears the enabled flag - nothing else in the app
/// reads the value. Pops `true` only on success; on a wrong PIN the dialog
/// stays open with the localized error and the attempt counter applies.
class DisablePinDialog extends StatefulWidget {
  const DisablePinDialog({super.key});

  /// Opens the dialog; returns `true` only when the lock was turned off.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DisablePinDialog(),
    );
    return result ?? false;
  }

  @override
  State<DisablePinDialog> createState() => _DisablePinDialogState();
}

class _DisablePinDialogState extends State<DisablePinDialog> {
  String _entered = '';

  Future<void> _submit() async {
    final controller = context.read<AppLockController>();
    final success = await controller.disablePin(_entered);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    // Wrong attempts below the limit keep only the inline error; reaching
    // the limit additionally posts the AppMessage warning with the cooldown.
    notifyLockout(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AppLockController>();
    final error = appLockErrorText(context, controller);

    return AlertDialog(
      title: Text(l10n.appLockDisableTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.appLockEnterPinPrompt,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PinInput(
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
              : Text(l10n.appLockActionConfirm),
        ),
      ],
    );
  }
}