import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';

class UpdateLanguageUseCase {
  const UpdateLanguageUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Result<AppSettings>> call(AppSettings current, String languageCode) async {
    final updated = current.copyWith(languageCode: languageCode);
    final result = await _repository.saveSettings(updated);
    return result.fold(
      (failure) => Result.failure(failure),
      (_) => Result.success(updated),
    );
  }
}
