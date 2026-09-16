# Architecture Rules

This document is normative: code that violates a rule here should be
treated as a defect, not a style preference.

## 1. Layers and dependency direction

```
Presentation → Domain ← Data
```

* **Domain** depends on nothing else in the app. It may import `dart:*`,
  `equatable`. It must **not** import `flutter/material.dart`,
  `flutter/widgets.dart`, `sembast`, or anything from `data/` or
  `presentation/`.
* **Data** depends on Domain (implements its repository contracts, returns
  its entities/failures) and on `core/database`. It must not import
  anything from `presentation/`.
* **Presentation** depends on Domain (entities, use cases) and on
  `core/widgets` / `core/extensions`. It must **never** import anything
  from a feature's `data/` folder, and must never call `sembast` or
  `DatabaseStore` directly.

Concretely: if you can `import 'package:.../data/...'` from a `presentation/`
file and it compiles, that import should not exist. Route through a use
case instead.

## 2. What each layer is allowed to contain

### `domain/entities/`
Immutable, `Equatable` value objects. No persistence concerns (no
`fromMap`/`toMap` — that belongs to the `data/models/` counterpart).

### `domain/repositories/`
`abstract interface class` contracts only. Return `Result<T>` from
`core/result`, never a raw `Future<T>` that can throw.

### `domain/usecases/`
One class per business operation, with a single `call(...)` method (or a
small number of clearly-named methods for closely related operations).
This is where **validation and business rules live** — never in a widget,
never in a repository implementation.

### `data/models/`
DTOs shaped for persistence, with `fromMap`/`toMap` and
`fromEntity`/`toEntity`. Kept separate from the domain entity so the
on-disk shape can change independently of the domain shape.

### `data/datasources/`
Talks to a `DatabaseStore<T>` (never to Sembast directly). Throws
`DatabaseException` on failure — never returns a `Result`, that
translation happens one layer up.

### `data/repositories/`
Implements the domain contract. Catches `DatabaseException` (and any other
data-layer exception) and returns a `Result<T>` carrying a typed
`Failure`. This is the **only** place that translation happens.

### `presentation/controllers/`
`ChangeNotifier` classes holding UI state (status enums, loaded data,
field-level errors). Call use cases; never call a repository or data
source directly. No `sembast`/`get_it` imports here — dependencies are
injected via the constructor.

### `presentation/pages/` and `presentation/widgets/`
Read state via `context.watch<Controller>()`, dispatch actions via
`context.read<Controller>()`. No business logic, no direct database calls,
no un-localized user-facing strings.

## 3. The database boundary

Only two classes in the entire codebase are allowed to import `package:sembast`:

* `core/database/local_database.dart` — owns the single `Database`
  connection lifecycle (open once, lazily; expose via `instance`).
* `core/database/database_store.dart` — generic typed CRUD wrapper over one
  Sembast store, parameterized by `fromMap`/`toMap`.

Every feature's data source is built by composing a `DatabaseStore<T>` —
never by writing `store.record(id).put(db, ...)` inline. If a new entity
needs storage, it gets a new `DatabaseStore<T>` registration in
`app/di/injector.dart`; `local_database.dart` and `database_store.dart`
never change.

## 4. Error handling

* `Failure` (`core/error/failure.dart`) is a sealed class:
  `DatabaseFailure`, `ValidationFailure`, `NetworkFailure`,
  `NotFoundFailure`, `UnexpectedFailure`.
* `Result<T>` (`core/result/result.dart`) is the sealed
  `Success<T>` / `ResultFailure<T>` wrapper every repository and use case
  returns.
* A raw exception must never cross from `data/` into `domain/` or
  `presentation/`. The repository implementation is the translation
  boundary — see rule 2's `data/repositories/` section.
* `ValidationFailure.fieldErrors` carries **message keys** (plain strings,
  e.g. `'validationNameRequired'`), not localized text — domain stays
  Flutter-free. The presentation layer maps key → `context.l10n` string
  (see `features/account/presentation/widgets/field_error_localizer.dart`
  for the pattern).

## 5. Dependency injection

`app/di/injector.dart` is the single composition root. It is the only file
in the app that:

* imports concrete implementations (`AccountRepositoryImpl`,
  `AccountLocalDataSource`, ...) rather than their abstractions, and
* knows the full dependency chain: `LocalDatabase → DatabaseStore<T> →
  DataSource → RepositoryImpl → UseCase → Controller`.

Everywhere else, depend on the abstraction (`AccountRepository`, not
`AccountRepositoryImpl`) and receive it via constructor injection. Widgets
obtain fully-wired controllers via `getIt<T>()` inside a `Provider`/
`ChangeNotifierProvider` in `app/app.dart` — they never call
`AccountRepositoryImpl()` or similar directly.

## 6. State management

`provider` + `ChangeNotifier`, consistently, across every feature. Do not
mix in a second state-management pattern (Bloc, Riverpod, GetX, ...)
without first updating this document and migrating existing features —
partial migrations are exactly the kind of inconsistency rule 11 in the
original spec warns against.

`setState()` is reserved for ephemeral, non-persisted, purely-local widget
state (e.g. a `TextEditingController`'s focus, a local "obscure password"
toggle). Anything that outlives the widget or represents a business
decision belongs in a controller.

## 7. Navigation

`go_router`, configured once in `app/router/app_router.dart`. Route paths
live in `AppRoutes` — no widget hardcodes a path string. The bottom-nav
tabs are a `StatefulShellRoute.indexedStack`, which keeps each tab's
Navigator (and therefore its state) alive across tab switches, so
switching tabs does not re-run a tab's initialization.

## 8. Adding a feature without touching existing ones

A new feature must be addable by:

1. Creating `features/<name>/{data,domain,presentation}/...`.
2. Adding its registrations to `app/di/injector.dart` (additive only).
3. Optionally adding a branch to `app/router/app_router.dart` (additive only).

If adding a feature requires editing an existing feature's internals
(beyond the two additive registration points above), the architecture
boundary has been violated somewhere and should be fixed before the
feature is added.

## 9. Non-negotiables (matching the original spec's hard constraints)

* No database access from `presentation/`.
* No business/validation logic in a widget.
* No hardcoded user-facing strings — everything through `context.l10n`.
* No hardcoded `Color(0xFF...)` — everything through the `ColorScheme` /
  `app/theme` tokens.
* No feature reaching into another feature's `data/` or `domain/` internals.
* No raw exception crossing from `data/` into `domain/`/`presentation/`.

## Future improvements (explicitly out of scope for this boilerplate)

These were identified while building the foundation but deliberately not
implemented, per the "don't expand scope" rule:

* Image picker / actual photo upload for the account avatar (the "Change
  photo" button is currently a disabled placeholder).
* Remote data source + connectivity-aware repository (the architecture
  already supports swapping `AccountRepositoryImpl`'s data source without
  touching domain/presentation, but no network code is included since
  rule 24 explicitly disallows a backend until it's needed).
* Golden/widget tests for pages (unit tests for use cases and repositories
  are included as the reference pattern; widget-level tests follow the
  same fake-based approach once specific UI behavior needs locking down).
* Additional bottom-nav tabs beyond Home/Account/Settings — the shell
  route structure supports adding one without refactoring, see README.
