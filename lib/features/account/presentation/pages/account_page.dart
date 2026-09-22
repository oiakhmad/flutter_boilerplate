import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/router/app_router.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_avatar.dart';
import 'package:flutter_clean_boilerplate/core/widgets/empty_state.dart';
import 'package:flutter_clean_boilerplate/core/widgets/error_view.dart';
import 'package:flutter_clean_boilerplate/core/widgets/loading_indicator.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/edit_account_page.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/widgets/remove_account_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountController>().load();
    });
  }

  Future<void> _openEdit() async {
    context.read<AccountController>().resetSaveStatus();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditAccountPage()),
    );
  }

  /// Opens the Remove Account confirmation dialog and, only on confirmed
  /// success, clears the first-run session and navigates to onboarding.
  ///
  /// The dialog itself performs the Sembast deletion via
  /// `AccountController.removeAccount()`. This handler only runs the
  /// post-success sequence: `SplashController.clearSession()` (so the
  /// router gate re-evaluates to "no account") followed by
  /// `go(/splash)`. On failure nothing is cleared and the dialog stays
  /// open with a localized error.
  Future<void> _handleRemoveAccount() async {
    context.read<AccountController>().resetRemoveStatus();
    final confirmed = await RemoveAccountDialog.show(context);
    if (!confirmed || !mounted) return;

    context.read<SplashController>().clearSession();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.removeAccountSuccess)),
    );
    context.go(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AccountController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: switch (controller.status) {
        AccountStatus.initial ||
        AccountStatus.loading =>
          LoadingIndicator(message: l10n.commonLoading),
        AccountStatus.error => ErrorView(
            failure: controller.failure!,
            onRetry: controller.load,
          ),
        AccountStatus.empty => EmptyState(
            title: l10n.accountEmptyTitle,
            message: l10n.accountEmptyMessage,
            icon: Icons.person_outline,
            actionLabel: l10n.accountCreateProfile,
            onAction: _openEdit,
          ),
        AccountStatus.loaded => _ProfileView(
            onEdit: _openEdit,
            onRemove: _handleRemoveAccount,
          ),
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.onEdit, required this.onRemove});

  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountController>().account!;
    final l10n = context.l10n;
    final dateFormat = DateFormat.yMMMMd(Localizations.localeOf(context).toString());

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: Column(
            children: [
              AppAvatar(name: account.name, imagePath: account.avatarPath, radius: 48),
              const SizedBox(height: AppSpacing.md),
              Text(account.name, style: context.textStyles.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                account.email,
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.accountMemberSince(dateFormat.format(account.createdAt)),
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.accountEditProfile),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onRemove,
          icon: Icon(Icons.delete_outline, color: context.colors.error),
          label: Text(
            l10n.removeAccountConfirmAction,
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}
