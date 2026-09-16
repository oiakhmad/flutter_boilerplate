import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';

/// Standard error state. Maps a [Failure] subtype to localized copy so
/// presentation widgets never format a raw exception message for the user.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  String _messageFor(BuildContext context, Failure failure) {
    final l10n = context.l10n;
    return switch (failure) {
      DatabaseFailure() => l10n.errorDatabase,
      ValidationFailure() => l10n.errorValidation,
      NetworkFailure() => l10n.errorDatabase,
      NotFoundFailure() => l10n.errorUnexpected,
      UnexpectedFailure() => l10n.errorUnexpected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.errorGenericTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _messageFor(context, failure),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onRetry, child: Text(context.l10n.actionRetry)),
            ],
          ],
        ),
      ),
    );
  }
}
