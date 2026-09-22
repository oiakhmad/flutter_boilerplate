import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/app.dart';
import 'package:flutter_clean_boilerplate/app/di/injector.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/controllers/settings_controller.dart';

/// Startup sequence (see ARCHITECTURE.md):
///   1. Bind the Flutter engine
///   2. Wire dependency injection (registers - but does not yet open - the
///      database; opening happens lazily on first real access)
///   3. Load persisted settings so the very first frame already reflects
///      the user's saved theme/language, instead of flashing a default
///      and then jumping
///   4. Resolve the first-run gate: does this device already have an
///      account? Doing it here - not on the Home screen - is what lets a
///      returning user go straight to Home without ever seeing the splash
///      form, and it never creates a second account.
///   5. Load the App Lock config: this arms the lifecycle observer and
///      resolves `isLocked` before the first frame, so a locked install
///      opens straight onto the Lock Screen instead of briefly showing
///      content behind it.
///   6. Run the app
///
/// Each step is awaited before the next starts, so there is no
/// initialization race: nothing in step 6 can run before steps 1-5
/// complete.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();
  await getIt<SettingsController>().load();
  await getIt<SplashController>().load();
  await getIt<AppLockController>().load();

  runApp(const App());
}
