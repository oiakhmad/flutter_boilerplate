import 'package:flutter_clean_boilerplate/core/config/app_config.dart';
import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/database/database_store.dart';
import 'package:flutter_clean_boilerplate/core/database/local_database.dart';
import 'package:flutter_clean_boilerplate/features/account/data/datasources/account_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';
import 'package:flutter_clean_boilerplate/features/account/data/repositories/account_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/create_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/remove_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/save_account.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/datasources/app_lock_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/datasources/app_lock_secure_data_source.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/models/app_lock_config_model.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/change_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/disable_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/enable_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/get_app_lock_config.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/recover_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/set_recovery_question.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_pin.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/domain/usecases/verify_recovery_answer.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/models/app_settings_model.dart';
import 'package:flutter_clean_boilerplate/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/get_settings.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_language.dart';
import 'package:flutter_clean_boilerplate/features/settings/domain/usecases/update_primary_color.dart';
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
    () => AccountLocalDataSource(
      getIt<DatabaseStore<AccountModel>>(),
      getIt<LocalDatabase>(),
    ),
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
  // First-run onboarding (splash) creates the account from a name only.
  getIt.registerLazySingleton<CreateAccountUseCase>(
    () => CreateAccountUseCase(getIt<AccountRepository>()),
  );
  getIt.registerLazySingleton<RemoveAccountUseCase>(
    () => RemoveAccountUseCase(getIt<AccountRepository>()),
  );
  getIt.registerFactory<AccountController>(
    () => AccountController(
      getAccount: getIt<GetAccountUseCase>(),
      saveAccount: getIt<SaveAccountUseCase>(),
      removeAccount: getIt<RemoveAccountUseCase>(),
    ),
  );

  // SplashController is a singleton (not a factory) like SettingsController:
  // main.dart resolves the first-run gate before runApp, the router gates on
  // that same instance, and app.dart exposes it to the widget tree.
  getIt.registerLazySingleton<SplashController>(
    () => SplashController(
      getAccount: getIt<GetAccountUseCase>(),
      createAccount: getIt<CreateAccountUseCase>(),
    ),
  );

  // --- App Lock feature -------------------------------------------------------
  // Two data sources: Sembast holds the non-sensitive config record, the
  // platform secure storage (Android Keystore / iOS Keychain) holds the
  // PIN and the recovery answer. Secrets never reach Sembast.
  getIt.registerLazySingleton<DatabaseStore<AppLockConfigModel>>(
    () => DatabaseStore<AppLockConfigModel>(
      database: getIt<LocalDatabase>(),
      storeName: StorageKeys.appLockStore,
      fromMap: AppLockConfigModel.fromMap,
      toMap: (model) => model.toMap(),
    ),
  );
  getIt.registerLazySingleton<AppLockLocalDataSource>(
    () => AppLockLocalDataSource(getIt<DatabaseStore<AppLockConfigModel>>()),
  );
  getIt.registerLazySingleton<AppLockSecureDataSource>(
    () => AppLockSecureDataSource(),
  );
  getIt.registerLazySingleton<AppLockRepository>(
    () => AppLockRepositoryImpl(
      getIt<AppLockLocalDataSource>(),
      getIt<AppLockSecureDataSource>(),
    ),
  );
  getIt.registerLazySingleton<GetAppLockConfigUseCase>(
    () => GetAppLockConfigUseCase(getIt<AppLockRepository>()),
  );
  getIt.registerLazySingleton<EnablePinUseCase>(
    () => EnablePinUseCase(getIt<AppLockRepository>()),
  );
  getIt.registerLazySingleton<DisablePinUseCase>(
    () => DisablePinUseCase(getIt<AppLockRepository>()),
  );
  getIt.registerLazySingleton<VerifyPinUseCase>(
    () => VerifyPinUseCase(getIt<AppLockRepository>()),
  );
  getIt.registerLazySingleton<VerifyRecoveryAnswerUseCase>(
    () => VerifyRecoveryAnswerUseCase(getIt<AppLockRepository>()),
  );
  getIt.registerLazySingleton<ChangePinUseCase>(
    () => ChangePinUseCase(getIt<AppLockRepository>()),
  );
  getIt.registerLazySingleton<SetRecoveryQuestionUseCase>(
    () => SetRecoveryQuestionUseCase(getIt<AppLockRepository>()),
  );
  getIt.registerLazySingleton<RecoverPinUseCase>(
    () => RecoverPinUseCase(getIt<AppLockRepository>()),
  );

  // AppLockController is a singleton (not a factory): main.dart loads the
  // config (and arms the lifecycle lock) before runApp, the router gates
  // on that same instance, and app.dart exposes it to the widget tree.
  getIt.registerLazySingleton<AppLockController>(
    () => AppLockController(
      getConfig: getIt<GetAppLockConfigUseCase>(),
      enablePin: getIt<EnablePinUseCase>(),
      disablePin: getIt<DisablePinUseCase>(),
      verifyPin: getIt<VerifyPinUseCase>(),
      verifyRecoveryAnswer: getIt<VerifyRecoveryAnswerUseCase>(),
      changePin: getIt<ChangePinUseCase>(),
      setRecoveryQuestion: getIt<SetRecoveryQuestionUseCase>(),
      recoverPin: getIt<RecoverPinUseCase>(),
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
  getIt.registerLazySingleton<UpdatePrimaryColorUseCase>(
    () => UpdatePrimaryColorUseCase(getIt<SettingsRepository>()),
  );

  // SettingsController is a singleton (not a factory): the whole app
  // shares one instance because it drives MaterialApp's theme/locale.
  getIt.registerLazySingleton<SettingsController>(
    () => SettingsController(
      getSettings: getIt<GetSettingsUseCase>(),
      updateThemeMode: getIt<UpdateThemeModeUseCase>(),
      updateLanguage: getIt<UpdateLanguageUseCase>(),
      updatePrimaryColor: getIt<UpdatePrimaryColorUseCase>(),
    ),
  );
}
