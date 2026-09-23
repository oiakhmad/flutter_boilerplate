# Flutter Clean Architecture Boilerplate

A production-oriented Flutter starting point built on **Clean Architecture**
and a **feature-first** folder structure, with **Sembast** for local
persistence, **provider** for state, **get_it** for dependency injection,
**go_router** for navigation, and full **English/Indonesian** localization.
It ships with four features — Home, Account, Settings and App Lock — as
reference implementations, not as the point of the project. The point is
the foundation underneath them.

## Features

Every feature lives self-contained under `lib/features/<name>/` and is
wired through the single composition root (`app/di/injector.dart`):

| Feature | Path | What it includes |
|---|---|---|
| **Home** | `features/home` | Bottom-nav landing tab — intentionally presentation-only (no state to persist yet). |
| **Account** | `features/account` | Full slice: first-run Splash onboarding (the account is created once), profile view, edit profile, and remove account (wipes the local database). |
| **Settings** | `features/settings` | Full slice: theme (Light/Dark/System), primary color (presets + custom picker), and language (EN/ID) — all persisted to Sembast and applied live without restart. |
| **App Lock** | `features/app_lock` | Full slice powering **Keamanan Aplikasi**: 6-digit PIN App Lock with create/confirm and change-PIN flows, a router-gated Lock Screen (cold start *and* after backgrounding), an attempt limit with 30s lockout notified via an `AppMessage` warning, and a recovery security question. Secrets live in `flutter_secure_storage`; only non-sensitive config in Sembast. Opened from Settings → Keamanan Aplikasi. |

Home, Account and Settings are **reference implementations** of the
architecture; App Lock additionally demonstrates secure storage and the
lifecycle/router gate (documented in `.ai/features-app-lock.md`).

> ⚠️ This project was generated without a Flutter SDK / pub.dev access in
> the generating environment, so it has **not** been run through
> `flutter pub get`, `flutter analyze`, or `flutter test` yet. See
> [Getting started](#getting-started) below — do this first.

## Getting started

```bash
# 1. Generate platform folders (android/, ios/, web/, ...) - not included
#    in this archive since they're machine/toolchain-generated.
flutter create .

# 2. Fetch dependencies
flutter pub get

# 3. Generate localization code (lib/l10n/generated/app_localizations.dart)
#    flutter pub get usually triggers this automatically because pubspec.yaml
#    sets `generate: true`; run it explicitly if the import doesn't resolve.
flutter gen-l10n

# 4. Verify
flutter analyze
flutter test

# 5. Run (falls back to bundled defaults — APP_ENV=dev)
flutter run
```

## Environments (compile-time configuration)

Environments are plain JSON files applied **at build time** via
`--dart-define-from-file` — no `.env` loader, no extra package, and no
runtime file reads:

```bash
flutter run --dart-define-from-file=config/dev.json
flutter run --dart-define-from-file=config/staging.json
flutter run --dart-define-from-file=config/production.json
```

| Key | Type | Purpose |
|---|---|---|
| `APP_ENV` | `String` | Environment name: `dev` / `staging` / `production` |
| `API_BASE_URL` | `String` | Backend base URL for that environment |
| `APP_NAME` | `String` | Environment-specific app name (native/display/log use) |
| `DB_NAME` | `String` | Sembast database file for that environment |
| `ENABLE_LOGGING` | `bool` | Whether verbose logging is allowed in that build |
| `API_TIMEOUT_SECONDS` | `int` | Request timeout for that environment |

Each environment opens its **own** Sembast file, so `dev` data can never
leak into `staging` or `production`:

| Environment | `DB_NAME` |
|---|---|
| dev | `my_app_dev.db` |
| staging | `my_app_staging.db` |
| production | `my_app_production.db` |

`lib/core/config/app_config.dart` is the **only** file in the app that
calls `String.fromEnvironment` / `bool.fromEnvironment` /
`int.fromEnvironment`. Everything else reads the typed values:

```dart
final dbName = AppConfig.dbName;            // e.g. 'my_app_dev.db'
final environment = AppConfig.environment;  // AppEnvironment.dev
final baseUrl = AppConfig.apiBaseUrl;
final hasLogging = AppConfig.enableLogging;
```

Rules of the road:

* `config/*.json` is gitignored, so create your local file from the
  committed twin: `cp config/dev.json.example config/dev.json`.
* Running without a define file (`flutter run`) still works — the app
  falls back to the bundled defaults (`APP_ENV=dev` and
  `AppConstants.databaseFileName`), which is exactly what the code did
  before environments were introduced.
* Nothing outside `AppConfig` may branch on the environment; `features/`
  never asks "am I in dev?".
* Switching environments is a JSON edit, never a code edit.

## First-run flow (Splash → Home)

`main()` answers one question before the first frame — *does this device
already have an account?* — and the router acts on the answer:

```
main()
 ├─ setupDependencies()
 ├─ getIt<SettingsController>().load()
 └─ getIt<SplashController>().load()      # first-run gate (one Sembast read)
runApp(App) → MaterialApp.router(routerConfig: appRouter)
      └─ redirect: _guardFirstRun (app/router/app_router.dart)
           ├─ account stored → /home     # splash is never built
           └─ no account     → /splash   # Welcome + Name + Next
```

* `SplashController` is the gate; `hasAccount` is the only thing the router
  looks at, and the redirect is re-evaluated automatically because the
  controller is the router's `refreshListenable` — so the splash screen
  contains no navigation code and no path strings.
* **Next** calls `CreateAccountUseCase` (domain), which owns the rules: the
  name must be non-blank and at least 2 characters, and the account is
  created **once** — when an account already exists nothing is written, so
  re-entering the flow can never duplicate or overwrite it.
* The account is an ordinary Sembast record (`StorageKeys.currentAccountId`)
  in the active environment's database, so it survives restarts, rebuilds
  and re-installs as long as app data is not cleared.
* A storage failure becomes the splash error state with a retry action —
  the gate never lets an exception reach the widget tree.
* Onboarding is part of the `account` feature (`create_account.dart`,
  `splash_controller.dart`, `splash_page.dart`) because a separate feature
  would have to import another feature's domain to create the account —
  which [ARCHITECTURE.md](ARCHITECTURE.md) rule 9 forbids.

## Architecture overview

Clean Architecture with three layers per feature, dependency direction
enforced one-way:

```
Presentation → Domain ← Data
```

* **Presentation** (widgets, controllers) never imports Sembast or knows
  about repository implementations — only domain entities and use cases.
* **Domain** (entities, repository *contracts*, use cases) is plain Dart:
  no `flutter/material.dart`, no `sembast`, no data-layer imports.
* **Data** (models, data sources, repository *implementations*) is the only
  layer allowed to import Sembast, and the only layer that knows the app
  uses Sembast at all.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full rule set and the
reasoning behind each one.

## Folder structure

```
lib/
├── app/             # Composition: DI, router, theme, app shell
│   ├── di/          # get_it wiring — the one file that knows every
│   │                # concrete class in the app
│   ├── router/      # go_router config + bottom-nav shell
│   └── theme/       # design tokens (colors, spacing, typography) + ThemeData
├── core/            # Cross-feature, feature-agnostic building blocks
│   ├── config/      # AppConfig — the only reader of --dart-define-from-file
│   ├── database/    # LocalDatabase (Sembast lifecycle) + DatabaseStore<T>
│   ├── error/       # Failure hierarchy
│   ├── result/       # Result<T> success/failure wrapper
│   ├── constants/   # Storage keys, app-wide constants
│   ├── extensions/  # BuildContext convenience getters
│   ├── utils/       # Pure validators
│   └── widgets/     # Reusable UI: loading/empty/error states, form fields
├── features/
│   ├── home/        # presentation only — no state to persist yet
│   ├── account/     # full data/domain/presentation slice (incl. first-run Splash)
│   ├── app_lock/    # full slice — App Lock (PIN 6-Digit) / Keamanan Aplikasi
│   └── settings/    # full data/domain/presentation slice
└── main.dart
```

Each feature under `features/` is self-contained: `data/`, `domain/`,
`presentation/`. A feature never imports another feature's internals.

## Database architecture

```
Widget/Controller → UseCase → Repository (contract, in domain)
                                   ↑ implements
                              RepositoryImpl (in data)
                                   ↓ uses
                              DataSource (in data)
                                   ↓ uses
                              DatabaseStore<T> (in core, generic)
                                   ↓ uses
                              LocalDatabase (in core, opens Sembast once)
```

* `LocalDatabase` opens the single Sembast file **once**, lazily, the first
  time anything asks for it — not on every screen.
* `DatabaseStore<T>` is a generic, reusable typed wrapper over one Sembast
  store. It is the *only* class permitted to call Sembast APIs directly.
* Every data source throws `DatabaseException`; every repository
  implementation catches it and returns a `Result<T>` carrying a
  `Failure` — nothing above the data layer ever sees a raw exception.

## State management

`provider` + `ChangeNotifier` controllers, one per feature
(`AccountController`, `SettingsController`, `AppLockController`).
Controllers:

* hold UI state (`status` enums, loaded data, field errors),
* call use cases — never a repository or data source directly,
* are exposed to widgets via `context.watch<T>()` / `context.read<T>()`.

`setState()` is used only for purely local, non-persisted widget state
(e.g. text field focus); it never carries business logic.

## Localization

Flutter's official ARB-based `gen-l10n` pipeline — no third-party i18n
package.

* Source of truth: `lib/l10n/app_en.arb` (template) and `lib/l10n/app_id.arb`.
* Generated output: `lib/l10n/generated/app_localizations.dart` (gitignored,
  regenerated by `flutter gen-l10n` / `flutter pub get`).
* Access from widgets via `context.l10n.someKey` (see
  `core/extensions/context_extensions.dart`).
* **No user-facing string may be hardcoded.** Everything — including
  validation and error messages — is localized.

## Theming

`Light` / `Dark` / `System`, selected in Settings and persisted to Sembast
via `SettingsController`. All colors come from a single seeded
`ColorScheme` (`app/theme/app_colors.dart`); no widget hardcodes a
`Color(0xFF...)`. Spacing uses a 4pt-grid scale in `app/theme/app_spacing.dart`.

## How to add a new feature

Say you want to add `Transaction`:

1. `lib/features/transaction/domain/entities/transaction.dart` — plain Dart
   entity, `Equatable`.
2. `lib/features/transaction/domain/repositories/transaction_repository.dart`
   — abstract interface returning `Result<T>`.
3. `lib/features/transaction/domain/usecases/...` — one class per business
   operation (`GetTransactions`, `SaveTransaction`, ...). Put validation
   here, not in a widget.
4. `lib/features/transaction/data/models/transaction_model.dart` — DTO with
   `fromMap`/`toMap`.
5. `lib/features/transaction/data/datasources/transaction_local_data_source.dart`
   — wraps a `DatabaseStore<TransactionModel>`.
6. `lib/features/transaction/data/repositories/transaction_repository_impl.dart`
   — implements the domain contract, translates `DatabaseException` → `Failure`.
7. `lib/features/transaction/presentation/controllers/transaction_controller.dart`
   — `ChangeNotifier`, calls use cases.
8. `lib/features/transaction/presentation/pages/...` — widgets, `context.watch`.
9. Register everything in `app/di/injector.dart` (mirror the Account block).
10. Add a `StatefulShellBranch` + `NavigationDestination` in
    `app/router/app_router.dart` if it needs a bottom-nav tab.

No existing feature needs to change.

## How to add a new entity to the database

1. Add a store name to `core/constants/storage_keys.dart`.
2. Register a `DatabaseStore<YourModel>` in `app/di/injector.dart`, passing
   `fromMap`/`toMap`.
3. Build a data source around it. Never call `stringMapStoreFactory` or a
   `StoreRef` outside `core/database/database_store.dart`.

## How to add localization

1. Add the key to `lib/l10n/app_en.arb` (with a `@key` description if it
   takes placeholders).
2. Add the same key to `lib/l10n/app_id.arb` with the Indonesian text.
3. Run `flutter gen-l10n` (or `flutter pub get`).
4. Use `context.l10n.yourKey` in the widget.

## How to add a theme token

1. Add the token to the relevant file in `app/theme/` (`app_colors.dart`
   for colors, `app_spacing.dart` for spacing, `app_typography.dart` for
   text styles).
2. Reference it via `context.colors` / `context.textStyles` / the token
   constant — never inline a raw value in a widget.

## How to write tests

Every boundary in this architecture is a seam for a hand-rolled fake — see
`test/features/account/` for two examples:

* `test/features/account/domain/usecases/save_account_test.dart` — tests
  validation + business rules against a fake `AccountRepository`, no
  database involved.
* `test/features/account/data/repositories/account_repository_impl_test.dart`
  — tests that a thrown `DatabaseException` is correctly translated into a
  `DatabaseFailure`, using a fake data source.

Pattern for a new use case or repository test: implement the interface it
depends on with a small in-file fake class (see the examples), no mocking
framework or code generation required.

## Package choices & rationale

| Package | Why |
|---|---|
| `provider` | Flutter-team-endorsed, minimal ceremony, pairs naturally with `ChangeNotifier` controllers |
| `get_it` | Simple, mature service locator; used only in `app/di` |
| `go_router` | Official declarative router with first-class bottom-nav shell support (`StatefulShellRoute`) |
| `sembast` + `path_provider` | Pure-Dart embedded NoSQL store — no native build step, works across all Flutter targets |
| `equatable` | Removes boilerplate `==`/`hashCode` on entities/failures |
| `uuid` | Standard id generation, in case a future entity needs generated (not fixed) ids |
| `intl` | Required by Flutter's official ARB localization pipeline |

Nothing here solves a problem `dart:core`/Flutter could solve alone — see
`core/result/result.dart` and `core/utils/validators.dart` for the reverse
case: deliberately hand-rolled instead of adding a dependency.
