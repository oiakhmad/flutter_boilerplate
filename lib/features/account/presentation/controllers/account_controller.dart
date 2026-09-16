import 'package:flutter/foundation.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/get_account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/save_account.dart';

enum AccountStatus { initial, loading, loaded, empty, error }

enum SaveStatus { idle, saving, success, error }

/// Owns Account-feature UI state and delegates every business decision to
/// use cases. Widgets read state via [ChangeNotifier]/`context.watch`; they
/// never touch the repository, data source, or Sembast directly.
class AccountController extends ChangeNotifier {
  AccountController({
    required GetAccountUseCase getAccount,
    required SaveAccountUseCase saveAccount,
  })  : _getAccount = getAccount,
        _saveAccount = saveAccount;

  final GetAccountUseCase _getAccount;
  final SaveAccountUseCase _saveAccount;

  AccountStatus status = AccountStatus.initial;
  Account? account;
  Failure? failure;

  SaveStatus saveStatus = SaveStatus.idle;
  Map<String, String> saveFieldErrors = const {};
  Failure? saveFailure;

  Future<void> load() async {
    status = AccountStatus.loading;
    notifyListeners();

    final result = await _getAccount();
    result.fold(
      (f) {
        failure = f;
        status = AccountStatus.error;
      },
      (value) {
        account = value;
        status = value == null ? AccountStatus.empty : AccountStatus.loaded;
      },
    );
    notifyListeners();
  }

  Future<bool> save({
    required String name,
    required String email,
    String? avatarPath,
  }) async {
    saveStatus = SaveStatus.saving;
    saveFieldErrors = const {};
    saveFailure = null;
    notifyListeners();

    final result = await _saveAccount(
      SaveAccountParams(name: name, email: email, avatarPath: avatarPath),
      existing: account,
    );

    return result.fold(
      (f) {
        saveStatus = SaveStatus.error;
        saveFailure = f;
        if (f is ValidationFailure) {
          saveFieldErrors = f.fieldErrors;
        }
        notifyListeners();
        return false;
      },
      (saved) {
        account = saved;
        status = AccountStatus.loaded;
        saveStatus = SaveStatus.success;
        notifyListeners();
        return true;
      },
    );
  }

  void resetSaveStatus() {
    saveStatus = SaveStatus.idle;
    saveFieldErrors = const {};
    saveFailure = null;
  }
}
