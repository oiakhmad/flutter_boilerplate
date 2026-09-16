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
          RadioListTile<AppThemeMode>(
            title: Text(l10n.settingsThemeSystem),
            value: AppThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (mode) => controller.setThemeMode(mode!),
          ),
          RadioListTile<AppThemeMode>(
            title: Text(l10n.settingsThemeLight),
            value: AppThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (mode) => controller.setThemeMode(mode!),
          ),
          RadioListTile<AppThemeMode>(
            title: Text(l10n.settingsThemeDark),
            value: AppThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (mode) => controller.setThemeMode(mode!),
          ),
          const Divider(height: AppSpacing.xl),
          _SectionHeader(title: l10n.settingsLanguage),
          RadioListTile<String>(
            title: Text(l10n.settingsLanguageEnglish),
            value: 'en',
            groupValue: settings.languageCode,
            onChanged: (code) => controller.setLanguageCode(code!),
          ),
          RadioListTile<String>(
            title: Text(l10n.settingsLanguageIndonesian),
            value: 'id',
            groupValue: settings.languageCode,
            onChanged: (code) => controller.setLanguageCode(code!),
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
