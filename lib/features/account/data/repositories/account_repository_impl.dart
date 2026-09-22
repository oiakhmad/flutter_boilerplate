import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/data/datasources/account_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';

/// Data-layer implementation of the domain [AccountRepository] contract.
///
/// Its one job beyond delegating to the data source: catch
/// [DatabaseException] and translate it into a [Failure] before it can
/// reach the domain/presentation layers.
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._dataSource);

  final AccountLocalDataSource _dataSource;

  @override
  Future<Result<Account?>> getAccount() async {
    try {
      final model = await _dataSource.getAccount();
      return Result.success(model?.toEntity());
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> saveAccount(Account account) async {
    try {
      await _dataSource.saveAccount(AccountModel.fromEntity(account));
      return const Result.success(null);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> removeAccount() async {
    try {
      await _dataSource.deleteAllLocalData();
      return const Result.success(null);
    } on DatabaseException catch (error) {
      return Result.failure(DatabaseFailure(error.message));
    } catch (error) {
      return Result.failure(UnexpectedFailure(error.toString()));
    }
  }
}
