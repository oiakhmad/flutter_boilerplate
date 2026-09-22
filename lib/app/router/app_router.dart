import 'package:flutter/material.dart';
import 'package:flutter_clean_boilerplate/app/di/injector.dart';
import 'package:flutter_clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/controllers/splash_controller.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/account_page.dart';
import 'package:flutter_clean_boilerplate/features/account/presentation/pages/splash_page.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/controllers/app_lock_controller.dart';
import 'package:flutter_clean_boilerplate/features/app_lock/presentation/pages/lock_page.dart';
import 'package:flutter_clean_boilerplate/features/home/presentation/pages/home_page.dart';
import 'package:flutter_clean_boilerplate/features/settings/presentation/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

/// Route paths, centralized so no widget ever hardcodes a path string.
abstract final class AppRoutes {
  /// First-run entry screen - shown only while no account exists yet.
  static const String splash = '/splash';

  /// App Lock screen - shown while the PIN lock is engaged.
  static const String lock = '/lock';

  static const String home = '/home';
  static const String account = '/account';
  static const String settings = '/settings';
}

/// Adding a new bottom-nav tab means adding one branch here and one
/// destination in `_AppBottomNavShell` below - no other file changes.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  // Two gates react to state changes: the first-run gate
  // (SplashController) and the App Lock gate (AppLockController - the
  // lifecycle observer flips `isLocked` when the app goes to the
  // background). Merging both listentables makes the router re-evaluate
  // [_guard] the moment either one changes.
  refreshListenable: Listenable.merge([
    getIt<SplashController>(),
    getIt<AppLockController>(),
  ]),
  redirect: _guard,
  routes: [
    // App Lock screen, outside the bottom-nav shell: shown before there is
    // anything to navigate between while the lock is engaged.
    GoRoute(
      path: AppRoutes.lock,
      builder: (context, state) => const LockPage(),
    ),
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

/// The single place that decides "Locked, Splash or Home?".
///
/// - Lock engaged → every location is funnelled to [/lock], remembering
///   where the user was ([AppLockController.returnLocation]); the system
///   back button cannot escape the lock because the redirect simply sends
///   it back to /lock.
/// - Lock disengaged while sitting on /lock → the remembered location is
///   restored (Home when it is gone), then the first-run gate runs - so
///   unlocking returns the user exactly where they were, except on cold
///   start where the remembered /splash resolves through the first-run
///   gate to Home.
/// - Lock off entirely → the gate reduces to [_guardFirstRun].
///
/// Both gates read their state from composition-root singletons
/// ([AppLockController], [SplashController]), so the router does not need
/// a [BuildContext].
String? _guard(BuildContext context, GoRouterState state) {
  final appLock = getIt<AppLockController>();
  final location = state.matchedLocation;

  if (appLock.isLocked) {
    // Already on the lock screen: keep the previously remembered origin
    // (returning early means this branch never overwrites it with /lock).
    if (location == AppRoutes.lock) return null;
    appLock.returnLocation = location;
    return AppRoutes.lock;
  }
  if (location == AppRoutes.lock) {
    return appLock.returnLocation ?? AppRoutes.home;
  }
  return _guardFirstRun(context, state);
}

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
///
/// Styling is intentionally clean and minimal: the M3 `NavigationBar`
/// indicator is transparent (see `navigationBarTheme`), so the active
/// destination is distinguished by icon + label color only —
/// `ColorScheme.primary` for active, `ColorScheme.onSurfaceVariant` for
/// inactive — with a slightly bolder active label. Colors resolve from the
/// ambient `ColorScheme`, so light/dark/custom seeds are followed
/// automatically, and the bar's built-in animation keeps the transition
/// smooth. Labels are always shown.
class _AppBottomNavShell extends StatelessWidget {
  const _AppBottomNavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    Widget destination({
      required IconData icon,
      required IconData activeIcon,
      required String label,
    }) {
      return NavigationDestination(
        icon: Icon(icon, color: inactiveColor),
        selectedIcon: Icon(activeIcon, color: activeColor),
        label: label,
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? activeColor : inactiveColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            destination(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: l10n.navHome,
            ),
            destination(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: l10n.navAccount,
            ),
            destination(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
