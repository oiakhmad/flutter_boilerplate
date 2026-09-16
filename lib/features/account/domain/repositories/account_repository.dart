import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';

/// Contract owned by the domain layer. The data layer provides the
/// implementation ([AccountRepositoryImpl]); nothing in domain or
/// presentation knows - or needs to know - that it is backed by Sembast.
abstract interface class AccountRepository {
  /// Returns `null` (wrapped in a successful [Result]) when no profile has
  /// been created yet - this is a normal empty state, not a failure.
  Future<Result<Account?>> getAccount();

  Future<Result<void>> saveAccount(Account account);
}
