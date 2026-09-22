import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/datasources/app_lock_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/datasources/app_lock_secure_data_source.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/models/app_lock_config_model.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Data-layer implementation of the domain [AppLockRepository] contract.
///
/// Its one job beyond delegating to the two data sources: catch
/// [DatabaseException] (whether it came from Sembast or from the secure
/// vault) and translate it into a typed [Failure] before it can reach the
/// domain/presentation layers. Verification results map to the contract's
/// documented shape: match -> `true`, mismatch -> `false`, nothing stored
/// -> [NotFoundFailure].
class AppLockRepositoryImpl implements AppLockRepository {
  AppLockRepositoryImpl(this._local, this._secure);

  final AppLockLocalDataSource _local;
  final AppLockSecureDataSource _secure;

  @override
  Future<Result<AppLockConfig>> getConfig() async {
    try {
      final model = await _local.getConfig();
      return Result.success(model?.toEntity() ?? AppLockConfig.initial());
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<AppLockConfig>> saveConfig(AppLockConfig config) async {
    try {
      final model = AppLockConfigModel.fromEntity(config);
      await _local.saveConfig(model);
      return Result.success(config);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> savePin(String pin) async {
    try {
      await _secure.writePin(pin);
      return const Result.success(null);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<bool>> verifyPin(String pin) async {
    try {
      final stored = await _secure.readPin();
      if (stored == null) {
        return const Result.failure(NotFoundFailure('PIN is not set'));
      }
      return Result.success(stored == pin);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> clearPin() async {
    try {
      await _secure.deletePin();
      return const Result.success(null);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> saveRecoveryAnswer(String answer) async {
    try {
      await _secure.writeRecoveryAnswer(answer);
      return const Result.success(null);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<bool>> verifyRecoveryAnswer(String answer) async {
    try {
      final stored = await _secure.readRecoveryAnswer();
      if (stored == null) {
        return const Result.failure(
          NotFoundFailure('Recovery answer is not set'),
        );
      }
      return Result.success(stored == answer);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }
}