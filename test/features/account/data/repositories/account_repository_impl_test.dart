import 'package:flutter_clean_boilerplate/core/database/database_exception.dart';
import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/features/account/data/datasources/account_local_data_source.dart';
import 'package:flutter_clean_boilerplate/features/account/data/models/account_model.dart';
import 'package:flutter_clean_boilerplate/features/account/data/repositories/account_repository_impl.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingDataSource implements AccountLocalDataSource {
  @override
  Future<AccountModel?> getAccount() =>
      throw const DatabaseException('disk unavailable');

  @override
  Future<void> saveAccount(AccountModel model) =>
      throw const DatabaseException('disk unavailable');
}

void main() {
  test('getAccount translates DatabaseException into DatabaseFailure', () async {
    final repository = AccountRepositoryImpl(_ThrowingDataSource());

    final result = await repository.getAccount();

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<DatabaseFailure>());
  });

  test('saveAccount translates DatabaseException into DatabaseFailure', () async {
    final repository = AccountRepositoryImpl(_ThrowingDataSource());
    final account = Account(
      id: 'x',
      name: 'A',
      email: 'a@b.com',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    final result = await repository.saveAccount(account);

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}
