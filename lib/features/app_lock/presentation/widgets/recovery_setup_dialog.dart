import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_text_field.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/app_lock_constants.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/app_lock_strings.dart';
import 'package:provider/provider.dart';

/// Dialog for choosing the recovery security question and its answer.
///
/// The question comes from the fixed preset list
/// ([AppLockConstants.recoveryQuestionIds], localized per id); the answer
/// goes to secure storage through `AppLockController.setRecoveryQuestion`
/// and is never written to Sembast. Pops `true` only on success.
class RecoverySetupDialog extends StatefulWidget {
  const RecoverySetupDialog({super.key});

  /// Opens the dialog; returns `true` only when the question + answer were
  /// saved.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RecoverySetupDialog(),
    );
    return result ?? false;
  }

  @override
  State<RecoverySetupDialog> createState() => _RecoverySetupDialogState();
}

class _RecoverySetupDialogState extends State<RecoverySetupDialog> {
  late final TextEditingController _answerController;
  String? _selectedQuestionId;

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
    final questionId = _selectedQuestionId ??
        controller.config.recoveryQuestionId ??
        AppLockConstants.recoveryQuestionIds.first;
    final success = await controller.setRecoveryQuestion(
      questionId,
      _answerController.text,
    );
    if (!mounted) return;
    if (success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AppLockController>();
    final currentQuestionId = controller.config.recoveryQuestionId ??
        AppLockConstants.recoveryQuestionIds.first;
    final effectiveQuestionId = _selectedQuestionId ?? currentQuestionId;
    final answer = _answerController.text.trim();
    final error = localizeAppLockFailure(
      context,
      controller.failure,
      lockoutSeconds: controller.lockoutSecondsRemaining,
    );

    return AlertDialog(
      title: Text(l10n.appLockRecoveryTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.appLockRecoverySetupMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: effectiveQuestionId,
              items: [
                for (final id in AppLockConstants.recoveryQuestionIds)
                  DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      recoveryQuestionLabel(context, id),
                      style: context.textStyles.bodyMedium,
                    ),
                  ),
              ],
              onChanged: controller.isBusy
                  ? null
                  : (id) => setState(() => _selectedQuestionId = id),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.appLockRecoveryAnswerLabel,
              hint: l10n.appLockRecoveryAnswerHint,
              controller: _answerController,
              enabled: !controller.isBusy,
              autofocus: true,
              obscureText: true,
              textInputAction: TextInputAction.done,
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
              answer.isNotEmpty && !controller.isBusy ? _submit : null,
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