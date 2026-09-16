import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/models/app_settings_model.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._dataSource);

  final SettingsLocalDataSource _dataSource;

  @override
  Future<Result<AppSettings>> getSettings() async {
    try {
      final model = await _dataSource.getSettings();
      return Result.success(model?.toEntity() ?? AppSettings.initial());
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> saveSettings(AppSettings settings) async {
    try {
      await _dataSource.saveSettings(AppSettingsModel.fromEntity(settings));
      return const Result.success(null);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }
}
