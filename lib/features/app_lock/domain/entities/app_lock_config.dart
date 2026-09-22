import 'package:equatable/equatable.dart';

/// Domain entity for the persisted App Lock configuration.
///
/// Deliberately contains **no secrets**: the PIN and the recovery answer
/// never touch Sembast (or any other non-secure storage) - they live in the
/// platform's secure storage (see
/// `features/app_lock/data/datasources/app_lock_secure_data_source.dart`).
/// This record only carries the non-sensitive flags the lock needs:
///
/// - [isEnabled] - whether the user turned the PIN lock on.
/// - [recoveryQuestionId] - stable id of the chosen preset recovery
///   question (localized text lives in l10n, keyed by this id).
/// - [failedAttempts] / [lockoutUntil] - brute-force throttling state, so
///   the attempt budget survives an app restart.
class AppLockConfig extends Equatable {
  const AppLockConfig({
    required this.isEnabled,
    required this.recoveryQuestionId,
    required this.failedAttempts,
    required this.lockoutUntil,
  });

  /// Lock off, no recovery question, fresh attempt budget - the state of a
  /// device that has never configured App Lock.
  factory AppLockConfig.initial() => const AppLockConfig(
        isEnabled: false,
        recoveryQuestionId: null,
        failedAttempts: 0,
        lockoutUntil: null,
      );

  final bool isEnabled;

  /// `null` until the user configures a recovery question.
  final String? recoveryQuestionId;

  /// Consecutive failed unlock attempts since the last successful
  /// verification (or since an expired lockout was cleared).
  final int failedAttempts;

  /// When the current lockout window ends, or `null` when not locked out.
  final DateTime? lockoutUntil;

  /// Whether a recovery question has been configured.
  bool get hasRecoveryQuestion => recoveryQuestionId != null;

  static const Object _keepLockout = Object();

  /// Returns a copy with the given non-null fields replaced.
  ///
  /// [lockoutUntil] takes an explicit `null` to *clear* the lockout (the
  /// usual "successful verification resets the throttle" path); omitting the
  /// argument keeps the current value. The other fields cannot be cleared to
  /// `null` because their types are non-nullable.
  AppLockConfig copyWith({
    bool? isEnabled,
    String? recoveryQuestionId,
    int? failedAttempts,
    Object? lockoutUntil = _keepLockout,
  }) {
    return AppLockConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      recoveryQuestionId: recoveryQuestionId ?? this.recoveryQuestionId,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: identical(lockoutUntil, _keepLockout)
          ? this.lockoutUntil
          : lockoutUntil as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        recoveryQuestionId,
        failedAttempts,
        lockoutUntil,
      ];
}