import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/app_lock_strings.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/pin_input.dart';
import 'package:provider/provider.dart';

/// Two-step dialog for creating the App Lock PIN (enable flow): choose a
/// 6-digit PIN, then confirm it. The dialog performs the save through
/// `AppLockController.enablePin` and only pops `true` on success - on
/// failure it stays open and shows the localized error (same contract as
/// `RemoveAccountDialog`).
class PinSetupDialog extends StatefulWidget {
  const PinSetupDialog({super.key});

  /// Opens the dialog; returns `true` only when the PIN was created and
  /// the lock is now enabled.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinSetupDialog(),
    );
    return result ?? false;
  }

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  bool _confirming = false;
  String _createdPin = '';
  String _entered = '';

  Future<void> _submit() async {
    if (!_confirming) {
      setState(() {
        _createdPin = _entered;
        _confirming = true;
        _entered = '';
      });
      return;
    }
    final controller = context.read<AppLockController>();
    final success = await controller.enablePin(_createdPin, _entered);
    if (!mounted) return;
    if (success) Navigator.of(context).pop(true);
    // On failure the dialog stays open; controller.failure carries the
    // localized error rendered below the input.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AppLockController>();
    final error = localizeAppLockFailure(
      context,
      controller.failure,
      lockoutSeconds: controller.lockoutSecondsRemaining,
    );

    return AlertDialog(
      title: Text(_confirming ? l10n.appLockConfirmPinTitle : l10n.appLockCreatePinTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _confirming
                ? l10n.appLockConfirmPinPrompt
                : l10n.appLockCreatePinPrompt,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Keyed by step so the field starts empty on the confirm step.
          PinInput(
            key: ValueKey(_confirming),
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
          onPressed: _entered.length == 6 && !controller.isBusy
              ? _submit
              : null,
          child: controller.isBusy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _confirming ? l10n.appLockActionConfirm : l10n.appLockActionNext,
                ),
        ),
      ],
    );
  }
}