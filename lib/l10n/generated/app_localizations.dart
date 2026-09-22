import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// Application title shown in the OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Flutter Boilerplate'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a placeholder feature. Replace it with your first real screen.'**
  String get homeWelcomeMessage;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountFieldName;

  /// No description provided for @accountFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountFieldEmail;

  /// Shown on the profile page
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String accountMemberSince(String date);

  /// No description provided for @accountEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get accountEditProfile;

  /// No description provided for @accountChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get accountChangePhoto;

  /// No description provided for @accountSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get accountSave;

  /// No description provided for @accountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountCancel;

  /// Success message after the profile is updated
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get accountUpdateSuccess;

  /// Error message when updating the profile fails
  ///
  /// In en, this message translates to:
  /// **'Profile couldn\'t be updated. Please try again.'**
  String get accountUpdateFailure;

  /// No description provided for @accountEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No profile yet'**
  String get accountEmptyTitle;

  /// No description provided for @accountEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your profile to get started.'**
  String get accountEmptyMessage;

  /// No description provided for @accountCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get accountCreateProfile;

  /// No description provided for @splashWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get splashWelcomeTitle;

  /// No description provided for @splashNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get splashNameHint;

  /// No description provided for @splashNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get splashNext;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get settingsLanguageIndonesian;

  /// Section title for the primary seed-color picker in Settings
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get settingsPrimaryColor;

  /// Label for the custom-color option in the primary color picker
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsPrimaryColorCustom;

  /// Helper text under the custom-color option
  ///
  /// In en, this message translates to:
  /// **'Pick your favorite color — it becomes the seed for the whole color scheme.'**
  String get settingsPrimaryColorCustomHint;

  /// Title of the custom color picker dialog
  ///
  /// In en, this message translates to:
  /// **'Choose custom color'**
  String get settingsPrimaryColorChooseTitle;

  /// Confirm button in the custom color picker dialog
  ///
  /// In en, this message translates to:
  /// **'Use this color'**
  String get settingsPrimaryColorUseColor;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least {min} characters'**
  String validationNameTooShort(int min);

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach local storage. Please try again.'**
  String get errorDatabase;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please fix the highlighted fields.'**
  String get errorValidation;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get errorUnexpected;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// Title of the remove-account confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get removeAccountTitle;

  /// Warning shown in the remove-account confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all local data on this device. This action cannot be undone.'**
  String get removeAccountMessage;

  /// Label above the confirmation input; {word} is DELETE or HAPUS
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String removeAccountConfirmLabel(String word);

  /// Placeholder inside the confirmation input
  ///
  /// In en, this message translates to:
  /// **'Confirmation word'**
  String get removeAccountConfirmHint;

  /// Confirmation word when the active language is Indonesian
  ///
  /// In en, this message translates to:
  /// **'HAPUS'**
  String get removeAccountConfirmWordId;

  /// Confirmation word when the active language is English
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get removeAccountConfirmWordEn;

  /// Destructive confirm button in the remove-account dialog
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get removeAccountConfirmAction;

  /// Cancel button in the remove-account dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get removeAccountCancel;

  /// Loading state while the local database is being deleted
  ///
  /// In en, this message translates to:
  /// **'Deleting account…'**
  String get removeAccountDeleting;

  /// Success message after the account is removed
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get removeAccountSuccess;

  /// Failure message when account deletion fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get removeAccountFailure;

  /// Hint shown when the typed confirmation word is wrong
  ///
  /// In en, this message translates to:
  /// **'Input does not match the confirmation word'**
  String get removeAccountMismatch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
