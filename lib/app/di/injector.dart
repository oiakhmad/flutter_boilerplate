import 'package:flutter_clean_boilerplate/core/config/app_config.dart';
import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/core/database/local_database.dart';
import 'package:flutter_clean_boilerplate/features/account/data/datasources/account_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';
import 'package:flutter_clean_boilerplate/features/account/data/repositories/account_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/save_account.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/models/app_settings_model.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/get_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_language.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_theme_mode.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/controllers/settings_controller.dart';
import 'package:get_it/get_it.dart';

/// The single composition root of the app.
///
/// Every dependency chain (Database -> DataSource -> Repository -> UseCase
/// -> Controller) is wired exactly once, here. Nothing outside this file
/// should ever construct a repository, data source, or use case directly -
/// features pull fully-wired controllers out of [getIt] instead.
///
/// To add a new entity/feature, mirror the Account block below: register
/// its `DatabaseStore<T>`, data source, repository, use cases, and
/// controller as `factory`s (controllers) or `lazySingleton`s
/// (stateless dependencies).
final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // --- Core ----------------------------------------------------------------
  // The database file is the active environment's `DB_NAME`
  // (`config/<env>.json`), so each environment gets its own Sembast file.
  getIt.registerLazySingleton<LocalDatabase>(
    () => LocalDatabase(fileName: AppConfig.dbName),
  );

  // --- Account feature -------------------------------------------------------
  getIt.registerLazySingleton<DatabaseStore<AccountModel>>(
    () => DatabaseStore<AccountModel>(
      database: getIt<LocalDatabase>(),
      storeName: StorageKeys.accountStore,
      fromMap: AccountModel.fromMap,
      toMap: (model) => model.toMap(),
    ),
  );
  getIt.registerLazySingleton<AccountLocalDataSource>(
    () => AccountLocalDataSource(getIt<DatabaseStore<AccountModel>>()),
  );
  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(getIt<AccountLocalDataSource>()),
  );
  getIt.registerLazySingleton<GetAccountUseCase>(
    () => GetAccountUseCase(getIt<AccountRepository>()),
  );
  getIt.registerLazySingleton<SaveAccountUseCase>(
    () => SaveAccountUseCase(getIt<AccountRepository>()),
  );
  getIt.registerFactory<AccountController>(
    () => AccountController(
      getAccount: getIt<GetAccountUseCase>(),
      saveAccount: getIt<SaveAccountUseCase>(),
    ),
  );

  // --- Settings feature -------------------------------------------------------
  getIt.registerLazySingleton<DatabaseStore<AppSettingsModel>>(
    () => DatabaseStore<AppSettingsModel>(
      database: getIt<LocalDatabase>(),
      storeName: StorageKeys.settingsStore,
      fromMap: AppSettingsModel.fromMap,
      toMap: (model) => model.toMap(),
    ),
  );
  getIt.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSource(getIt<DatabaseStore<AppSettingsModel>>()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(getIt<SettingsLocalDataSource>()),
  );
  getIt.registerLazySingleton<GetSettingsUseCase>(
    () => GetSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<UpdateThemeModeUseCase>(
    () => UpdateThemeModeUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<UpdateLanguageUseCase>(
    () => UpdateLanguageUseCase(getIt<SettingsRepository>()),
  );

  // SettingsController is a singleton (not a factory): the whole app
  // shares one instance because it drives MaterialApp's theme/locale.
  getIt.registerLazySingleton<SettingsController>(
    () => SettingsController(
      getSettings: getIt<GetSettingsUseCase>(),
      updateThemeMode: getIt<UpdateThemeModeUseCase>(),
      updateLanguage: getIt<UpdateLanguageUseCase>(),
    ),
  );
}
