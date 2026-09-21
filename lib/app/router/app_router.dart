import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/di/injector.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/account_page.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/splash_page.dart';
import 'package:flutter_clean_boilerplate/features/home/presentation/pages/home_page.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

/// Route paths, centralized so no widget ever hardcodes a path string.
abstract final class AppRoutes {
  /// First-run entry screen - shown only while no account exists yet.
  static const String splash = '/splash';

  static const String home = '/home';
  static const String account = '/account';
  static const String settings = '/settings';
}

/// Adding a new bottom-nav tab means adding one branch here and one
/// destination in `_AppBottomNavShell` below - no other file changes.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  // The first-run gate is a ChangeNotifier, so the router re-evaluates
  // [_guardFirstRun] the moment the account appears - that is how the splash
  // screen leaves for Home without knowing any route path itself.
  refreshListenable: getIt<SplashController>(),
  redirect: _guardFirstRun,
  routes: [
    // Entry screen, outside the bottom-nav shell: it is shown before there
    // is anything to navigate between.
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _AppBottomNavShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.account,
              builder: (context, state) => const AccountPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// The single place that decides "Splash or Home?".
///
/// - No account yet → every location is funnelled to Splash, so the app can
///   never reach Home without completing onboarding.
/// - Account exists → Splash is skipped entirely: a returning user lands on
///   Home with no splash frame and no name form, because the gate is already
///   resolved (before the first frame) in `main.dart`.
///
/// The gate is read from the `SplashController` singleton - the composition
/// root owns that instance, so the router does not need a `BuildContext`.
String? _guardFirstRun(BuildContext context, GoRouterState state) {
  final hasAccount = getIt<SplashController>().hasAccount;
  final atSplash = state.matchedLocation == AppRoutes.splash;

  if (!hasAccount) return atSplash ? null : AppRoutes.splash;
  return atSplash ? AppRoutes.home : null;
}

/// Persistent bottom-navigation scaffold.
///
/// `StatefulShellRoute` keeps each branch's Navigator (and its state) alive
/// across tab switches, so switching tabs never re-runs a tab's expensive
/// initialization - it only changes which branch is visible.
class _AppBottomNavShell extends StatelessWidget {
  const _AppBottomNavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navAccount,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
