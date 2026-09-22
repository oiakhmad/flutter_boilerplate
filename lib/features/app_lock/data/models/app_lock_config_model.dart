import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';

/// DTO for the single-record App Lock config persisted in Sembast.
///
/// Contains no secrets by design (see [AppLockConfig]); `lockoutUntil` is
/// encoded as an ISO-8601 string, matching `AppSettingsModel`'s date
/// convention. Decoding is defensive against missing keys, wrong types and
/// corrupt values, so a bad record can never crash startup.
class AppLockConfigModel {
  const AppLockConfigModel({
    required this.isEnabled,
    required this.recoveryQuestionId,
    required this.failedAttempts,
    required this.lockoutUntil,
  });

  final bool isEnabled;
  final String? recoveryQuestionId;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  factory AppLockConfigModel.fromEntity(AppLockConfig config) {
    return AppLockConfigModel(
      isEnabled: config.isEnabled,
      recoveryQuestionId: config.recoveryQuestionId,
      failedAttempts: config.failedAttempts,
      lockoutUntil: config.lockoutUntil,
    );
  }

  AppLockConfig toEntity() => AppLockConfig(
        isEnabled: isEnabled,
        recoveryQuestionId: recoveryQuestionId,
        failedAttempts: failedAttempts,
        lockoutUntil: lockoutUntil,
      );

  factory AppLockConfigModel.fromMap(String id, Map<String, Object?> map) {
    final enabled = map['isEnabled'];
    final questionId = map['recoveryQuestionId'];
    final attempts = map['failedAttempts'];
    final lockout = map['lockoutUntil'];
    return AppLockConfigModel(
      isEnabled: enabled is bool ? enabled : false,
      recoveryQuestionId: questionId is String ? questionId : null,
      failedAttempts: attempts is int && attempts >= 0 ? attempts : 0,
      lockoutUntil: lockout is String ? DateTime.tryParse(lockout) : null,
    );
  }

  Map<String, Object?> toMap() => {
        'isEnabled': isEnabled,
        if (recoveryQuestionId != null)
          'recoveryQuestionId': recoveryQuestionId,
        'failedAttempts': failedAttempts,
        if (lockoutUntil != null) 'lockoutUntil': lockoutUntil!.toIso8601String(),
      };
}