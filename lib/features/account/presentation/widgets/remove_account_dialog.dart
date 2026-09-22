import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_text_field.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:provider/provider.dart';

/// Confirmation dialog for the Remove Account flow.
///
/// The user must type the locale-specific confirmation word exactly
/// (`DELETE` for English, `HAPUS` for Indonesian) before the destructive
/// action becomes available. Comparison is intentionally strict: the input
/// must equal the expected word after trimming surrounding whitespace -
/// no case folding, no partial matching - so the destructive gesture is
/// unambiguous.
class RemoveAccountDialog extends StatefulWidget {
  const RemoveAccountDialog({super.key});

  /// Opens the dialog. Returns `true` only when the caller should proceed
  /// with the removal + session cleanup + navigation sequence.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RemoveAccountDialog(),
    );
    return result ?? false;
  }

  @override
  State<RemoveAccountDialog> createState() => _RemoveAccountDialogState();
}

class _RemoveAccountDialogState extends State<RemoveAccountDialog> {
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _confirmController = TextEditingController()
      ..addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _confirmController
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  /// Rebuilds on every keystroke so the delete button enablement and the
  /// mismatch hint stay in sync with the typed input.
  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  /// Expected word follows the *active* locale (`DELETE` vs `HAPUS`).
  String _expectedWord(BuildContext context) {
    final l10n = context.l10n;
    return Localizations.localeOf(context).languageCode == 'id'
        ? l10n.removeAccountConfirmWordId
        : l10n.removeAccountConfirmWordEn;
  }

  Future<void> _handleDelete() async {
    final accountController = context.read<AccountController>();
    final success = await accountController.removeAccount();
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    }
    // On failure the dialog stays open: AccountController.removeFailure
    // now carries the failure and the body renders it with localized copy.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AccountController>();
    final expectedWord = _expectedWord(context);
    final matches = _confirmController.text.trim() == expectedWord;
    final isRemoving =
        controller.removeStatus == RemoveAccountStatus.removing;
    return AlertDialog(
      title: Text(l10n.removeAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.removeAccountMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.removeAccountConfirmLabel(expectedWord),
              hint: l10n.removeAccountConfirmHint,
              controller: _confirmController,
              enabled: !isRemoving,
              autofocus: true,
              textInputAction: TextInputAction.done,
              errorText: _confirmController.text.isEmpty || matches
                  ? null
                  : l10n.removeAccountMismatch,
            ),
            if (controller.removeStatus == RemoveAccountStatus.error) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.removeAccountFailure,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ],
            if (isRemoving) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.removeAccountDeleting,
                      style: context.textStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              isRemoving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.removeAccountCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          onPressed: (!matches || isRemoving) ? null : _handleDelete,
          child: Text(l10n.removeAccountConfirmAction),
        ),
      ],
    );
  }
}