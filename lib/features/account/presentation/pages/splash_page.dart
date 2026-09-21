import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/core/widgets/app_text_field.dart';
import 'package:flutter_clean_boilerplate/core/widgets/error_view.dart';
import 'package:flutter_clean_boilerplate/core/widgets/loading_indicator.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/widgets/field_error_localizer.dart';
import 'package:provider/provider.dart';

/// The app's entry screen and first-run gate.
///
/// It answers one question - "does this device already have an account?" -
/// and shows a single name field only when the answer is no:
///
/// - account already stored → this screen is never shown; the router's guard
///   goes straight to Home (see `app/router/app_router.dart`).
/// - no account → Welcome + Name + Next; `Next` validates, stores the
///   account once, and the guard then moves the user to Home.
///
/// No database access and no navigation logic live here: it reads state from
/// [SplashController] and, on success, lets the router react to
/// `SplashController` becoming ready - which keeps route paths in one place
/// (`AppRoutes`).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    // The gate is normally already resolved in `main()` before the first
    // frame. This covers the remaining case - landing on /splash before the
    // controller has run - so the screen never sits on a spinner forever.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<SplashController>();
      if (controller.status == SplashStatus.initial) {
        controller.load();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    await context.read<SplashController>().submitName(_nameController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<SplashController>();

    return Scaffold(
      body: SafeArea(
        child: switch (controller.status) {
          // `ready` keeps showing the loading state for the instant before
          // the router redirects to Home.
          SplashStatus.initial ||
          SplashStatus.checking ||
          SplashStatus.ready =>
            LoadingIndicator(message: l10n.commonLoading),
          SplashStatus.error => ErrorView(
              failure: controller.failure!,
              onRetry: controller.load,
            ),
          SplashStatus.needsName => _WelcomeForm(
              nameController: _nameController,
              isSaving: controller.isSaving,
              nameErrorKey: controller.nameFieldErrors['name'],
              onNext: _handleNext,
            ),
        },
      ),
    );
  }
}

/// Welcome + Name + Next. Stateless: every value it shows comes from
/// [SplashController], and validation stays in `CreateAccountUseCase`.
class _WelcomeForm extends StatelessWidget {
  const _WelcomeForm({
    required this.nameController,
    required this.isSaving,
    required this.nameErrorKey,
    required this.onNext,
  });

  final TextEditingController nameController;
  final bool isSaving;
  final String? nameErrorKey;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.splashWelcomeTitle,
              textAlign: TextAlign.center,
              style: context.textStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: l10n.accountFieldName,
              hint: l10n.splashNameHint,
              controller: nameController,
              enabled: !isSaving,
              autofocus: true,
              textInputAction: TextInputAction.done,
              errorText: localizeFieldError(context, nameErrorKey),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: isSaving ? null : onNext,
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.splashNext),
            ),
          ],
        ),
      ),
    );
  }
}
