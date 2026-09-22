import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';

/// Severity of a transient user-facing message.
///
/// Visual mapping is centralized in [_AppMessageStyle]: every type derives
/// its colors from the ambient `ColorScheme`, so Light/Dark themes and
/// custom primary colors are followed automatically with no hardcoded
/// color per type.
enum AppMessageType { success, error, warning, info }

/// Standard transient message (SnackBar) used for all Success, Error,
/// Warning, and Information feedback.
///
/// Rules (see `.ai/conventions-and-howto.md` § "Message information"):
/// - Always pass an already-localized `message` (e.g. `l10n.profileUpdated`)
///   — never a hardcoded string.
/// - Prefer the `showSuccessMessage` / `showErrorMessage` /
///   `showWarningMessage` / `showInfoMessage` helpers over raw
///   `ScaffoldMessenger.of(context).showSnackBar(...)`.
class AppMessage {
  const AppMessage._();

  /// Shows a success message (e.g. after update profile succeeds).
  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, type: AppMessageType.success);
  }

  /// Shows an error message (e.g. when update profile fails).
  static void showError(BuildContext context, String message) {
    show(context, message: message, type: AppMessageType.error);
  }

  /// Shows a warning message.
  static void showWarning(BuildContext context, String message) {
    show(context, message: message, type: AppMessageType.warning);
  }

  /// Shows an informational message.
  static void showInfo(BuildContext context, String message) {
    show(context, message: message, type: AppMessageType.info);
  }

  /// Core entry point backing all typed helpers. Kept public so future
  /// call sites that already hold an [AppMessageType] (e.g. mapped from a
  /// `Failure`) do not need a new helper per type.
  static void show(
    BuildContext context, {
    required String message,
    required AppMessageType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final style = _AppMessageStyle.resolve(context, type);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(style.icon, color: style.foreground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: style.foreground,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: style.background,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          duration: duration,
        ),
      );
  }
}

/// Visual mapping from [AppMessageType] to semantic `ColorScheme` colors.
///
/// Every entry uses container/on-container pairs (`success` falls back to
/// `primaryContainer`/`onPrimaryContainer` because M3 `ColorScheme` has no
/// dedicated success role), so contrast stays comfortable in Light and
/// Dark themes without any hardcoded color.
class _AppMessageStyle {
  const _AppMessageStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;

  static _AppMessageStyle resolve(BuildContext context, AppMessageType type) {
    final scheme = context.colors;
    return switch (type) {
      AppMessageType.success => _AppMessageStyle(
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
          icon: Icons.check_circle_outline,
        ),
      AppMessageType.error => _AppMessageStyle(
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          icon: Icons.error_outline,
        ),
      AppMessageType.warning => _AppMessageStyle(
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
          icon: Icons.warning_amber_outlined,
        ),
      AppMessageType.info => _AppMessageStyle(
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
          icon: Icons.info_outline,
        ),
    };
  }
}

/// Backwards-compatible top-level helpers matching the `showSuccessMessage`
/// API referenced in the spec. New call sites may use either these or the
/// `AppMessage.showX` methods — both funnel into the same widget.
void showSuccessMessage(BuildContext context, {required String message}) {
  AppMessage.showSuccess(context, message);
}

/// Shows an error message.
void showErrorMessage(BuildContext context, {required String message}) {
  AppMessage.showError(context, message);
}

/// Shows a warning message.
void showWarningMessage(BuildContext context, {required String message}) {
  AppMessage.showWarning(context, message);
}

/// Shows an informational message.
void showInfoMessage(BuildContext context, {required String message}) {
  AppMessage.showInfo(context, message);
}
