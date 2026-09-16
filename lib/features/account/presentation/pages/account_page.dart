import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_avatar.dart';
import 'package:flutter_clean_boilerplate/core/widgets/empty_state.dart';
import 'package:flutter_clean_boilerplate/core/widgets/error_view.dart';
import 'package:flutter_clean_boilerplate/core/widgets/loading_indicator.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/edit_account_page.dart';
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
          ),
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.onEdit});

  final VoidCallback onEdit;

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
      ],
    );
  }
}
