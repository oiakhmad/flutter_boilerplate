import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';

/// Permanently removes the account and all local application data.
///
/// Thin pass-through to [AccountRepository.removeAccount]: there is no
/// business/validation rule here (the confirmation word is validated in
/// the presentation layer against the active locale). Keeping this use
/// case preserves the layering `Controller -> UseCase -> Repository` and
/// gives callers a single seam to fake in tests.
class RemoveAccountUseCase {
  const RemoveAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<void>> call() => _repository.removeAccount();
}
