import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/theme/app_spacing.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/controllers/settings_controller.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          _SectionHeader(title: l10n.settingsTheme),
          RadioGroup<AppThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) {
              if (mode != null) controller.setThemeMode(mode);
            },
            child: Column(
              children: [
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.settingsThemeSystem),
                  value: AppThemeMode.system,
                ),
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.settingsThemeLight),
                  value: AppThemeMode.light,
                ),
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.settingsThemeDark),
                  value: AppThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xl),
          _SectionHeader(title: l10n.settingsLanguage),
          RadioGroup<String>(
            groupValue: settings.languageCode,
            onChanged: (code) {
              if (code != null) controller.setLanguageCode(code);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(l10n.settingsLanguageEnglish),
                  value: 'en',
                ),
                RadioListTile<String>(
                  title: Text(l10n.settingsLanguageIndonesian),
                  value: 'id',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
