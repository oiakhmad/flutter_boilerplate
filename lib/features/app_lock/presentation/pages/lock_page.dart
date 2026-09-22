import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/error_view.dart';
import 'package:flutter_clean_boilerplate/core/widgets/loading_indicator.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/app_lock_strings.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/pin_input.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/widgets/recovery_unlock_dialog.dart';
import 'package:provider/provider.dart';

/// The App Lock screen shown before the app can be accessed while the PIN
/// lock is engaged.
///
/// It is a route (`/lock`) the router guard redirects to, not an overlay:
/// while locked, every location funnels here and the system back button
/// can only bounce back into the redirect - the content underneath is
/// never reachable. The page itself performs **no navigation**: it calls
/// `AppLockController.unlock`, and when `isLocked` clears the router's
/// `refreshListenable` fires and returns to `returnLocation` - the same
/// "the router moves the user" pattern as `SplashPage`.
///
/// Wrong PINs surface a localized error and feed the shared attempt
/// counter/lockout (a one-second [Timer] refreshes the cooldown text
/// while locked out). "Forgot PIN?" is only offered when a recovery
/// question has been configured.
class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  String _pin = '';
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  /// Keeps the countdown text ticking while a lockout window is active,
  /// and stops itself as soon as the window ends. Idempotent, so calling
  /// it on every rebuild is safe.
  void _syncLockoutTimer(AppLockController controller) {
    if (controller.isInLockout && _lockoutTimer == null) {
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (context.read<AppLockController>().isInLockout) {
          setState(() {});
        } else {
          _lockoutTimer?.cancel();
          _lockoutTimer = null;
          setState(() {});
        }
      });
    }
  }

  Future<void> _unlock() async {
    // Success clears isLocked; the router redirects back to where the user
    // was. On failure controller.failure renders the localized error and,
    // once the attempt limit has been reached, an AppMessage warning posts
    // the remaining cooldown.
    final controller = context.read<AppLockController>();
    final success = await controller.unlock(_pin);
    if (!mounted || success) return;
    notifyLockout(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<AppLockController>();
    _syncLockoutTimer(controller);

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
        final error = appLockErrorText(context, controller);
        body = Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: context.colors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.appLockLockedTitle,
                  textAlign: TextAlign.center,
                  style: context.textStyles.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.appLockLockedMessage,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PinInput(
                  autofocus: true,
                  enabled: !controller.isBusy,
                  onChanged: (value) => setState(() => _pin = value),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _pin.length == 6 &&
                          !controller.isBusy &&
                          !controller.isInLockout
                      ? _unlock
                      : null,
                  child: controller.isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.appLockUnlockAction),
                ),
                if (controller.config.hasRecoveryQuestion) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: controller.isBusy
                        ? null
                        : () {
                            RecoveryUnlockDialog.show(context);
                          },
                    child: Text(l10n.appLockForgotPin),
                  ),
                ],
              ],
            ),
          ),
        );
    }

    return Scaffold(
      body: SafeArea(child: body),
    );
  }
}