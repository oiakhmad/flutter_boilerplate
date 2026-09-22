import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/di/injector.dart';
import 'package:flutter_clean_boilerplate/app/router/app_router.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/account_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/controllers/settings_controller.dart';
import 'package:flutter_clean_boilerplate/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

/// Root widget. Its only responsibilities are: expose feature controllers
/// to the widget tree, and translate the persisted [SettingsController]
/// state into `MaterialApp.router`'s theme/locale. No feature or business
/// logic lives here.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared across the whole app - it backs MaterialApp's theme/locale.
        ChangeNotifierProvider<SettingsController>.value(
          value: getIt<SettingsController>(),
        ),
        // Startup gate, resolved in main() before the first frame: the
        // router and SplashPage read the same instance.
        ChangeNotifierProvider<SplashController>.value(
          value: getIt<SplashController>(),
        ),
        // New instance per subtree that needs it; get_it still owns wiring
        // of its dependencies.
        ChangeNotifierProvider<AccountController>(
          create: (_) => getIt<AccountController>(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: settings.lightTheme,
            darkTheme: settings.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
