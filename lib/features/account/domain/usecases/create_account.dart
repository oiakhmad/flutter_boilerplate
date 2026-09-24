import 'package:flutter_clean_boilerplate/core/constants/app_constants.dart';
import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/core/utils/validators.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';

/// Input for [CreateAccountUseCase]. The first-run splash form collects a
/// single field, so this carries a single field - identity, email and
/// timestamps are derived by the use case, never supplied by the UI.
class CreateAccountParams {
  const CreateAccountParams({required this.name});

  final String name;
}

/// Creates the local account **once**, from the first-run splash form.
///
/// Deliberately separate from [SaveAccountUseCase] rather than a special
/// case of it: first-run onboarding collects a name only (the email is
/// filled in later from the Account tab, where a *complete* valid profile
/// is required), while profile edits must keep requiring name + valid
/// email. Splitting them keeps both rules explicit instead of weakening
/// the edit form's validation.
///
/// Business rules (this is the only layer that owns them):
/// - the name must be non-blank and at least `AppConstants.nameMinLength`.
/// - idempotent: when an account already exists it is returned untouched
///   and **nothing is written**, so re-entering the splash flow can never
///   create a second account or overwrite the existing one.
class CreateAccountUseCase {
  const CreateAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<Account>> call(
    CreateAccountParams params, {
    required Account? existing,
  }) async {
    // Already onboarded: report success without touching storage.
    if (existing != null) return Result.success(existing);

    final nameResult = Validators.validateName(
      params.name,
      minLength: AppConstants.nameMinLength,
      maxLength: AppConstants.nameMaxLength,
    );
    if (!nameResult.isValid) {
      return Result.failure(
        ValidationFailure({'name': nameResult.errorCode!}),
      );
    }

    final now = DateTime.now();
    final account = Account(
      id: StorageKeys.currentAccountId,
      name: nameResult.normalizedValue!,
      // No email is collected yet; the Account tab lets the user add one.
      email: '',
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.saveAccount(account);
    return result.fold(
      (failure) => Result.failure(failure),
      (_) => Result.success(account),
    );
  }
}
