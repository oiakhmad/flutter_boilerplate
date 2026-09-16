// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Boilerplate';

  @override
  String get navHome => 'Home';

  @override
  String get navAccount => 'Account';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeWelcomeTitle => 'Welcome';

  @override
  String get homeWelcomeMessage =>
      'This is a placeholder feature. Replace it with your first real screen.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountFieldName => 'Name';

  @override
  String get accountFieldEmail => 'Email';

  @override
  String accountMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get accountEditProfile => 'Edit profile';

  @override
  String get accountChangePhoto => 'Change photo';

  @override
  String get accountSave => 'Save';

  @override
  String get accountCancel => 'Cancel';

  @override
  String get accountUpdateSuccess => 'Profile updated';

  @override
  String get accountEmptyTitle => 'No profile yet';

  @override
  String get accountEmptyMessage => 'Create your profile to get started.';

  @override
  String get accountCreateProfile => 'Create profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageIndonesian => 'Indonesian';

  @override
  String get validationNameRequired => 'Name is required';

  @override
  String validationNameTooShort(int min) {
    return 'Name must be at least $min characters';
  }

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorDatabase =>
      'We couldn\'t reach local storage. Please try again.';

  @override
  String get errorValidation => 'Please fix the highlighted fields.';

  @override
  String get errorUnexpected => 'An unexpected error occurred.';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionOk => 'OK';

  @override
  String get commonLoading => 'Loading…';
}
