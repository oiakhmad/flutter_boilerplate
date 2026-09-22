import 'package:flutter_clean_boilerplate/core/utils/validators.dart';

/// Non-secret App Lock policy constants.
///
/// Keeping the PIN rule and the brute-force throttling numbers in one place
/// lets every use case share a single definition without any of them
/// re-deriving the policy independently. None of these values are secret.
abstract final class AppLockConstants {
  /// The App Lock PIN must be exactly this many ASCII digits.
  static const int pinLength = 6;

  /// Failed unlock attempts allowed before the lockout window starts.
  static const int maxFailedAttempts = 5;

  /// How long verification is blocked after [maxFailedAttempts] failures.
  static const Duration lockoutDuration = Duration(seconds: 30);

  /// Stable ids of the preset recovery questions.
  ///
  /// Ids are locale-independent; the presentation layer maps each id to
  /// localized copy (`appLockQuestion*` l10n keys), and the domain uses the
  /// list to reject unknown ids before anything is written.
  static const List<String> recoveryQuestionIds = [
    'pet',
    'city',
    'teacher',
    'vehicle',
    'street',
  ];

  /// Single definition of the "valid PIN" rule: exactly [pinLength] ASCII
  /// digits. Used by every use case that accepts or creates a PIN.
  static bool isValidPin(String value) =>
      Validators.isDigitsOnly(value) &&
      Validators.hasExactLength(value, pinLength);
}