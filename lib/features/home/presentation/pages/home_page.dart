import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';

/// Placeholder landing feature.
///
/// Home intentionally has no `data`/`domain` layer: it has no state to
/// persist or business rule to enforce yet, so those folders would be
/// empty scaffolding with nothing in them - which rule 15 explicitly
/// disallows ("no unnecessary abstraction"). When Home needs real data,
/// add `data/`/`domain/` following the same pattern as `features/account`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_outlined, size: 48, color: context.colors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.homeWelcomeTitle, style: context.textStyles.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeWelcomeMessage,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
