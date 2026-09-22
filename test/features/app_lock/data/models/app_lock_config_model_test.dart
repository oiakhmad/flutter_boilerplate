import 'package:flutter_clean_boilerplate/features/app_lock/data/models/app_lock_config_model.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLockConfigModel persistence', () {
    test('round-trips a fully populated config', () {
      final lockout = DateTime(2024, 1, 1, 12, 30);
      final config = AppLockConfig(
        isEnabled: true,
        recoveryQuestionId: 'city',
        failedAttempts: 3,
        lockoutUntil: lockout,
      );

      final model = AppLockConfigModel.fromEntity(config);
      final decoded = AppLockConfigModel.fromMap(
        'app_lock_config',
        model.toMap(),
      );

      expect(decoded.toEntity(), config);
      expect(decoded.lockoutUntil, lockout);
    });

    test('round-trips the initial (all-default) config', () {
      final model =
          AppLockConfigModel.fromEntity(AppLockConfig.initial());

      final decoded = AppLockConfigModel.fromMap(
        'app_lock_config',
        model.toMap(),
      );

      expect(decoded.isEnabled, isFalse);
      expect(decoded.recoveryQuestionId, isNull);
      expect(decoded.failedAttempts, 0);
      expect(decoded.lockoutUntil, isNull);
      expect(decoded.toEntity(), AppLockConfig.initial());
    });

    test('falls back to defaults on missing keys', () {
      final decoded = AppLockConfigModel.fromMap('app_lock_config', const {});

      expect(decoded.isEnabled, isFalse);
      expect(decoded.recoveryQuestionId, isNull);
      expect(decoded.failedAttempts, 0);
      expect(decoded.lockoutUntil, isNull);
    });

    test('falls back to defaults on corrupt value types', () {
      final decoded = AppLockConfigModel.fromMap('app_lock_config', const {
        'isEnabled': 'yes',
        'recoveryQuestionId': 42,
        'failedAttempts': -7,
        'lockoutUntil': 'not-a-date',
      });

      expect(decoded.isEnabled, isFalse);
      expect(decoded.recoveryQuestionId, isNull);
      expect(decoded.failedAttempts, 0);
      expect(decoded.lockoutUntil, isNull);
    });

    test('omits optional keys from the map when null', () {
      final map = AppLockConfigModel.fromEntity(AppLockConfig.initial())
          .toMap();

      expect(map.containsKey('recoveryQuestionId'), isFalse);
      expect(map.containsKey('lockoutUntil'), isFalse);
      expect(map['isEnabled'], isFalse);
      expect(map['failedAttempts'], 0);
    });
  });
}