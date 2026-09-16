import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';

/// Fetches the current local profile, if one has been created.
class GetAccountUseCase {
  const GetAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<Account?>> call() => _repository.getAccount();
}
