import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/entities/primary_color_preference.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';

/// Persists a new primary-color preference (preset or custom ARGB).
///
/// Follows the same update convention as [UpdateThemeModeUseCase]:
/// receives the current [AppSettings], derives the updated entity, saves
/// it, and returns the new entity on success so the controller never has
/// to re-read storage. Validation is intentionally minimal — any
/// [PrimaryColorPreference] the domain can construct is persistable —
/// with `Result` failure propagation for storage errors.
class UpdatePrimaryColorUseCase {
  const UpdatePrimaryColorUseCase(this._repository);

  final SettingsRepository _repository;

  Future<Result<AppSettings>> call(
    AppSettings current,
    PrimaryColorPreference primaryColor,
  ) async {
    final updated = current.copyWith(primaryColor: primaryColor);
    final result = await _repository.saveSettings(updated);
    return result.fold(
      (failure) => Result.failure(failure),
      (_) => Result.success(updated),
    );
  }
}
