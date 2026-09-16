import 'package:flutter/widgets.dart';
import 'package:flutter_clean_boilerplate/core/constants/app_constants.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';

/// Maps the validation-failure message *keys* produced by
/// `SaveAccountUseCase` (plain strings, so domain stays Flutter-free) to
/// actual localized copy. This is the one seam between domain validation
/// codes and presentation-layer l10n.
String? localizeFieldError(BuildContext context, String? key) {
  if (key == null) return null;
  final l10n = context.l10n;
  return switch (key) {
    'validationNameRequired' => l10n.validationNameRequired,
    'validationNameTooShort' =>
      l10n.validationNameTooShort(AppConstants.nameMinLength),
    'validationEmailRequired' => l10n.validationEmailRequired,
    'validationEmailInvalid' => l10n.validationEmailInvalid,
    _ => null,
  };
}
