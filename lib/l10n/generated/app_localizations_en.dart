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
  String get accountUpdateFailure =>
      'Profile couldn\'t be updated. Please try again.';

  @override
  String get accountEmptyTitle => 'No profile yet';

  @override
  String get accountEmptyMessage => 'Create your profile to get started.';

  @override
  String get accountCreateProfile => 'Create profile';

  @override
  String get splashWelcomeTitle => 'Welcome';

  @override
  String get splashNameHint => 'Enter your name';

  @override
  String get splashNext => 'Next';

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
  String get settingsPrimaryColor => 'Primary color';

  @override
  String get settingsPrimaryColorCustom => 'Custom';

  @override
  String get settingsPrimaryColorCustomHint =>
      'Pick your favorite color — it becomes the seed for the whole color scheme.';

  @override
  String get settingsPrimaryColorChooseTitle => 'Choose custom color';

  @override
  String get settingsPrimaryColorUseColor => 'Use this color';

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

  @override
  String get removeAccountTitle => 'Delete account?';

  @override
  String get removeAccountMessage =>
      'This will permanently delete your account and all local data on this device. This action cannot be undone.';

  @override
  String removeAccountConfirmLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get removeAccountConfirmHint => 'Confirmation word';

  @override
  String get removeAccountConfirmWordId => 'HAPUS';

  @override
  String get removeAccountConfirmWordEn => 'DELETE';

  @override
  String get removeAccountConfirmAction => 'Delete account';

  @override
  String get removeAccountCancel => 'Cancel';

  @override
  String get removeAccountDeleting => 'Deleting account…';

  @override
  String get removeAccountSuccess => 'Account deleted';

  @override
  String get removeAccountFailure =>
      'We couldn\'t delete your account. Please try again.';

  @override
  String get removeAccountMismatch =>
      'Input does not match the confirmation word';

  @override
  String get appLockSecurityTitle => 'App Security';

  @override
  String get appLockSectionTitle => 'App Lock';

  @override
  String get appLockPinTitle => '6-Digit PIN Lock';

  @override
  String get appLockPinInactive => 'PIN not active';

  @override
  String get appLockPinActive => 'PIN active';

  @override
  String get appLockChangePinTitle => 'Change 6-Digit PIN';

  @override
  String get appLockChangePinInactiveHint => 'Enable the PIN lock first';

  @override
  String get appLockRecoveryTitle => 'Recovery Security Question';

  @override
  String get appLockRecoveryNotSet => 'Not set (Tap to set)';

  @override
  String get appLockRecoverySet => 'Configured (Tap to change)';

  @override
  String get appLockCreatePinTitle => 'Create PIN';

  @override
  String get appLockCreatePinPrompt => 'Enter a 6-digit PIN';

  @override
  String get appLockConfirmPinTitle => 'Confirm PIN';

  @override
  String get appLockConfirmPinPrompt => 'Re-enter the PIN to confirm';

  @override
  String get appLockDisableTitle => 'Turn off app lock?';

  @override
  String get appLockEnterPinPrompt => 'Enter your 6-digit PIN to continue';

  @override
  String get appLockNewPinPrompt => 'Enter a new 6-digit PIN';

  @override
  String get appLockConfirmNewPinPrompt => 'Re-enter the new PIN to confirm';

  @override
  String get appLockChangeOldPinPrompt => 'Enter your current PIN first';

  @override
  String get appLockActionNext => 'Next';

  @override
  String get appLockActionConfirm => 'Confirm';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get appLockPinInvalid => 'PIN must be exactly 6 digits';

  @override
  String get appLockPinMismatch => 'PINs do not match';

  @override
  String get appLockPinIncorrect => 'Incorrect PIN';

  @override
  String get appLockAlreadyEnabled => 'PIN lock is already enabled';

  @override
  String appLockTooManyAttempts(int seconds) {
    return 'Too many attempts. Try again in $seconds seconds.';
  }

  @override
  String get appLockAnswerRequired => 'Answer is required';

  @override
  String get appLockAnswerIncorrect => 'Incorrect answer';

  @override
  String get appLockQuestionInvalid => 'Select a valid question';

  @override
  String get appLockLockedTitle => 'App locked';

  @override
  String get appLockLockedMessage => 'Enter your PIN to unlock the app.';

  @override
  String get appLockUnlockAction => 'Unlock';

  @override
  String get appLockForgotPin => 'Forgot PIN?';

  @override
  String get appLockRecoverySetupMessage =>
      'Answer this question if you forget your PIN. It lets you set a new PIN without losing your data.';

  @override
  String get appLockRecoveryAnswerLabel => 'Answer';

  @override
  String get appLockRecoveryAnswerHint => 'Type your answer';

  @override
  String get appLockRecoveryUnlockTitle => 'Reset PIN';

  @override
  String get appLockRecoveryUnlockMessage =>
      'Answer your security question, then choose a new PIN.';

  @override
  String get appLockQuestionPet => 'What is the name of your first pet?';

  @override
  String get appLockQuestionCity => 'In what city were you born?';

  @override
  String get appLockQuestionTeacher => 'Who is your favorite teacher?';

  @override
  String get appLockQuestionVehicle => 'What was your first vehicle?';

  @override
  String get appLockQuestionStreet => 'On which street did you grow up?';

  @override
  String get appLockEnabled => 'App lock enabled';

  @override
  String get appLockDisabled => 'App lock disabled';

  @override
  String get appLockPinChanged => 'PIN changed successfully';

  @override
  String get appLockRecoverySaved => 'Recovery question saved';
}
