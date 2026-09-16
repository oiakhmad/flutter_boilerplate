import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_avatar.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_text_field.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/widgets/field_error_localizer.dart';
import 'package:provider/provider.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final account = context.read<AccountController>().account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _emailController = TextEditingController(text: account?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final controller = context.read<AccountController>();
    final success = await controller.save(
      name: _nameController.text,
      email: _emailController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountUpdateSuccess)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AccountController>();
    final isSaving = controller.saveStatus == SaveStatus.saving;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountEditProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  AppAvatar(name: _nameController.text, radius: 44),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: null, // Future improvement: image picker
                    child: Text(l10n.accountChangePhoto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.accountFieldName,
              controller: _nameController,
              enabled: !isSaving,
              textInputAction: TextInputAction.next,
              errorText: localizeFieldError(
                context,
                controller.saveFieldErrors['name'],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.accountFieldEmail,
              controller: _emailController,
              enabled: !isSaving,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              errorText: localizeFieldError(
                context,
                controller.saveFieldErrors['email'],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: isSaving ? null : _handleSave,
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.accountSave),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.accountCancel),
            ),
          ],
        ),
      ),
    );
  }
}
