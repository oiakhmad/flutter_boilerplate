import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';

/// Loads the App Lock configuration once during startup (see `main.dart`)
/// and on demand from the Security page's error/retry state.
class GetAppLockConfigUseCase {
  const GetAppLockConfigUseCase(this._repository);

  final AppLockRepository _repository;

  Future<Result<AppLockConfig>> call() => _repository.getConfig();
}