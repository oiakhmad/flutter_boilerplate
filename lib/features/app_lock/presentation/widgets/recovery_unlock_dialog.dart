import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_text_field.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/app_lock_strings.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/pin_input.dart';
import 'package:provider/provider.dart';

/// Forgot-PIN recovery flow (opened from the Lock Screen): answer the
/// security question (verified first, so a wrong answer stops the flow
/// early), then choose + confirm a new PIN. The final submission calls
/// `AppLockController.recoverPin`, which re-verifies the answer and the
/// new PIN atomically. Only the lock's own secrets are rewritten - the
/// account and business data are never touched.
class RecoveryUnlockDialog extends StatefulWidget {
  const RecoveryUnlockDialog({super.key});

  /// Opens the dialog; returns `true` only when a new PIN was set and the
  /// app is unlocked.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecoveryUnlockDialog(),
    );
    return result ?? false;
  }

  @override
  State<RecoveryUnlockDialog> createState() => _RecoveryUnlockDialogState();
}

class _RecoveryUnlockDialogState extends State<RecoveryUnlockDialog> {
  int _step = 0; // 0: recovery answer, 1: new PIN, 2: confirm new PIN.
  String _answer = '';
  String _newPin = '';
  String _entered = '';
  late final TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController()..addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _answerController
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final controller = context.read<AppLockController>();
    if (_step == 0) {
      final ok = await controller.verifyRecoveryAnswer(
        _answerController.text,
      );
      if (!mounted || !ok) return;
      setState(() {
        _answer = _answerController.text.trim();
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
    final success = await controller.recoverPin(_answer, _newPin, _entered);
    if (!mounted) return;
    if (success) Navigator.of(context).pop(true);
  }

  bool get _canSubmit {
    if (_step == 0) return _answerController.text.trim().isNotEmpty;
    return _entered.length == 6;
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

    final Widget input;
    String prompt;
    if (_step == 0) {
      prompt = recoveryQuestionLabel(
        context,
        controller.config.recoveryQuestionId,
      );
      input = AppTextField(
        label: l10n.appLockRecoveryAnswerLabel,
        hint: l10n.appLockRecoveryAnswerHint,
        controller: _answerController,
        enabled: !controller.isBusy,
        autofocus: true,
        obscureText: true,
        textInputAction: TextInputAction.done,
      );
    } else {
      prompt = _step == 1
          ? l10n.appLockNewPinPrompt
          : l10n.appLockConfirmNewPinPrompt;
      input = PinInput(
        key: ValueKey(_step),
        autofocus: true,
        enabled: !controller.isBusy,
        onChanged: (value) => setState(() => _entered = value),
      );
    }

    return AlertDialog(
      title: Text(l10n.appLockRecoveryUnlockTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.appLockRecoveryUnlockMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              prompt,
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            input,
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
              _canSubmit && !controller.isBusy ? _submit : null,
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