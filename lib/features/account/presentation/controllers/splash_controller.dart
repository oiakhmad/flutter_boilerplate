import 'package:flutter/foundation.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/create_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';

/// What the first-run gate needs from the UI right now.
enum SplashStatus {
  /// Nothing has been checked yet.
  initial,

  /// Reading the stored account.
  checking,

  /// No account on this device yet: the splash form must be shown.
  needsName,

  /// An account exists (or was just created): the app may enter Home.
  ready,

  /// Checking or creating failed; the UI offers a retry.
  error,
}

/// Owns the startup gate: *"has an account already been created on this
/// device?"*.
///
/// This is the account feature's onboarding slice, which is why it lives
/// here rather than in a separate feature: it is the only place allowed to
/// decide that the local account must be created, and it needs the account
/// use cases to do it. It owns no persistence of its own - it goes through
/// `GetAccountUseCase` / `CreateAccountUseCase` exactly like
/// `AccountController` does, so there is still one account record and one
/// database.
///
/// The controller is resolved during app startup (see `main.dart`) and
/// exposed to the router, which uses [hasAccount] to decide whether the
/// splash screen is shown at all:
///
/// - [SplashStatus.ready] / [hasAccount] `true` → straight to Home, the
///   name form is never built.
/// - [SplashStatus.needsName] → splash form; [submitName] creates the
///   account once, then the router moves on to Home.
class SplashController extends ChangeNotifier {
  SplashController({
    required GetAccountUseCase getAccount,
    required CreateAccountUseCase createAccount,
  })  : _getAccount = getAccount,
        _createAccount = createAccount;

  final GetAccountUseCase _getAccount;
  final CreateAccountUseCase _createAccount;

  SplashStatus status = SplashStatus.initial;
  Failure? failure;

  /// The stored account, or `null` while onboarding has not happened yet.
  Account? account;

  /// Non-empty only when an account exists - the flag the router gates on.
  bool get hasAccount => account != null;

  bool isSaving = false;

  /// Field name -> validation message key, same contract as
  /// `AccountController.saveFieldErrors` (localized by
  /// `localizeFieldError`).
  Map<String, String> nameFieldErrors = const {};

  /// Reads whether an account already exists. Called once during startup,
  /// and again from the splash screen's retry action on failure.
  ///
  /// A storage failure is reported as [SplashStatus.error] instead of
  /// throwing: the app stays usable and the user can retry.
  Future<void> load() async {
    status = SplashStatus.checking;
    failure = null;
    notifyListeners();

    final result = await _getAccount();
    result.fold(
      (f) {
        failure = f;
        status = SplashStatus.error;
      },
      (value) {
        account = value;
        status = value == null ? SplashStatus.needsName : SplashStatus.ready;
      },
    );
    notifyListeners();
  }

  /// Creates the account from the splash form.
  ///
  /// Returns `true` only when an account is now stored (including the case
  /// where one already existed), so the caller knows the gate is satisfied.
  /// Validation failures (blank/too short name) are surfaced through
  /// [nameFieldErrors] without any write being attempted.
  Future<bool> submitName(String name) async {
    isSaving = true;
    nameFieldErrors = const {};
    failure = null;
    notifyListeners();

    final result = await _createAccount(
      CreateAccountParams(name: name),
      existing: account,
    );

    return result.fold(
      (f) {
        failure = f;
        if (f is ValidationFailure) {
          nameFieldErrors = f.fieldErrors;
        }
        isSaving = false;
        notifyListeners();
        return false;
      },
      (created) {
        account = created;
        status = SplashStatus.ready;
        isSaving = false;
        notifyListeners();
        return true;
      },
    );
  }
}
