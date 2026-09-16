import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/app.dart';
import 'package:flutter_clean_boilerplate/app/di/injector.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/controllers/settings_controller.dart';

/// Startup sequence (see ARCHITECTURE.md):
///   1. Bind the Flutter engine
///   2. Wire dependency injection (registers - but does not yet open - the
///      database; opening happens lazily on first real access)
///   3. Load persisted settings so the very first frame already reflects
///      the user's saved theme/language, instead of flashing a default
///      and then jumping
///   4. Run the app
///
/// Each step is awaited before the next starts, so there is no
/// initialization race: nothing in step 4 can run before steps 1-3
/// complete.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();
  await getIt<SettingsController>().load();

  runApp(const App());
}
