import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_message.dart';
import 'package:flutter_clean_boilerplate/core/widgets/error_view.dart';
import 'package:flutter_clean_boilerplate/core/widgets/loading_indicator.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/change_pin_dialog.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/disable_pin_dialog.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/pin_setup_dialog.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/recovery_setup_dialog.dart';
import 'package:provider/provider.dart';

/// "App Security" page - the feature's home screen, pushed from Settings
/// as a non-tab detail route (same pattern as `EditAccountPage`).
///
/// Everything it shows comes from [AppLockController]; all business rules
/// live in the use cases behind it:
///
/// - **6-Digit PIN Lock** tile with the `PIN not active` / `PIN active`
///   status and a switch. Turning it on runs the two-step PIN setup
///   dialog; turning it off verifies the current PIN first. Cancelling a
///   dialog simply leaves the config (and therefore the switch) unchanged.
/// - **Change 6-Digit PIN** - only usable while the lock is active
///   (`enabled: false` otherwise), opens the old -> new -> confirm flow.
/// - **Recovery Security Question** - shows `Not set (Tap to set)` or the
///   configured status, opens the question + answer dialog.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  Future<void> _setPinLock(BuildContext context, bool enable) async {
    final bool ok;
    if (enable) {
      ok = await PinSetupDialog.show(context);
      if (!ok || !context.mounted) return;
      showSuccessMessage(context, message: context.l10n.appLockEnabled);
    } else {
      ok = await DisablePinDialog.show(context);
      if (!ok || !context.mounted) return;
      showSuccessMessage(context, message: context.l10n.appLockDisabled);
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final ok = await ChangePinDialog.show(context);
    if (!ok || !context.mounted) return;
    showSuccessMessage(context, message: context.l10n.appLockPinChanged);
  }

  Future<void> _setupRecovery(BuildContext context) async {
    final ok = await RecoverySetupDialog.show(context);
    if (!ok || !context.mounted) return;
    showSuccessMessage(context, message: context.l10n.appLockRecoverySaved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AppLockController>();

    final Widget body;
    switch (controller.status) {
      case AppLockStatus.initial:
      case AppLockStatus.loading:
        body = LoadingIndicator(message: l10n.commonLoading);
      case AppLockStatus.error:
        body = ErrorView(
          failure: controller.failure!,
          onRetry: controller.load,
        );
      case AppLockStatus.ready:
        final config = controller.config;
        body = ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            _SectionHeader(title: l10n.appLockSectionTitle),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.appLockPinTitle),
              subtitle: Text(
                config.isEnabled
                    ? l10n.appLockPinActive
                    : l10n.appLockPinInactive,
              ),
              trailing: Switch(
                value: config.isEnabled,
                onChanged: controller.isBusy
                    ? null
                    : (enable) => _setPinLock(context, enable),
              ),
            ),
            const Divider(height: AppSpacing.xl),
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: Text(l10n.appLockChangePinTitle),
              subtitle: config.isEnabled
                  ? null
                  : Text(l10n.appLockChangePinInactiveHint),
              enabled: config.isEnabled,
              onTap: config.isEnabled
                  ? () => _changePin(context)
                  : null,
            ),
            const Divider(height: AppSpacing.xl),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(l10n.appLockRecoveryTitle),
              subtitle: Text(
                config.hasRecoveryQuestion
                    ? l10n.appLockRecoverySet
                    : l10n.appLockRecoveryNotSet,
              ),
              onTap: () => _setupRecovery(context),
            ),
          ],
        );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appLockSecurityTitle)),
      body: body,
    );
  }
}

/// Section header styled exactly like the private one on `SettingsPage`
/// (primary-colored `titleMedium`), kept private per feature convention.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: context.textStyles.titleMedium
            ?.copyWith(color: context.colors.primary),
      ),
    );
  }
}