import 'package:flutter_clean_boilerplate/core/constants/app_constants.dart';
import 'package:flutter_clean_boilerplate/core/constants/storage_keys.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/core/utils/validators.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';

/// Input for [SaveAccountUseCase]. Carries only the fields a user edits -
/// identity/timestamps are derived by the use case, not supplied by the UI.
class SaveAccountParams {
  const SaveAccountParams({
    required this.name,
    required this.email,
    this.avatarPath,
  });

  final String name;
  final String email;
  final String? avatarPath;
}

/// Validates and persists profile edits.
///
/// This is where the business rule "an Account must have a non-empty name
/// of reasonable length and a valid email" lives - not in a widget, and
/// not scattered across the repository. On validation failure, no write
/// to storage is attempted.
class SaveAccountUseCase {
  const SaveAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<Account>> call(
    SaveAccountParams params, {
    required Account? existing,
  }) async {
    final fieldErrors = _validate(params);
    if (fieldErrors.isNotEmpty) {
      return Result.failure(ValidationFailure(fieldErrors));
    }

    final now = DateTime.now();
    final account = Account(
      id: existing?.id ?? StorageKeys.currentAccountId,
      name: params.name.trim(),
      email: params.email.trim(),
      avatarPath: params.avatarPath ?? existing?.avatarPath,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final result = await _repository.saveAccount(account);
    return result.fold(
      (failure) => Result.failure(failure),
      (_) => Result.success(account),
    );
  }

  Map<String, String> _validate(SaveAccountParams params) {
    final errors = <String, String>{};

    if (!Validators.isNotBlank(params.name)) {
      errors['name'] = 'validationNameRequired';
    } else if (!Validators.hasMinLength(params.name, AppConstants.nameMinLength)) {
      errors['name'] = 'validationNameTooShort';
    }

    if (!Validators.isNotBlank(params.email)) {
      errors['email'] = 'validationEmailRequired';
    } else if (!Validators.isValidEmail(params.email)) {
      errors['email'] = 'validationEmailInvalid';
    }

    return errors;
  }
}
