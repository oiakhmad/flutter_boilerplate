import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';

/// Small, focused convenience getters on [BuildContext].
///
/// These exist purely to remove repetitive
/// `AppLocalizations.of(context)!` / `Theme.of(context)` call sites across
/// the presentation layer - no business logic lives here.
extension AppContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get textStyles => Theme.of(this).textTheme;
}
