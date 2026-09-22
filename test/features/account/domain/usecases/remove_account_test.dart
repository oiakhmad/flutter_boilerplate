import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/remove_account.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake, matching the pattern used by `save_account_test.dart`:
/// no mocking framework, no database.
class _FakeAccountRepository implements AccountRepository {
  bool removeCalled = false;
  bool shouldFail = false;

  @override
  Future<Result<Account?>> getAccount() async => const Result.success(null);

  @override
  Future<Result<void>> saveAccount(Account account) async =>
      const Result.success(null);

  @override
  Future<Result<void>> removeAccount() async {
    removeCalled = true;
    if (shouldFail) {
      return const Result.failure(DatabaseFailure('disk full'));
    }
    return const Result.success(null);
  }
}

void main() {
  late _FakeAccountRepository repository;
  late RemoveAccountUseCase useCase;

  setUp(() {
    repository = _FakeAccountRepository();
    useCase = RemoveAccountUseCase(repository);
  });

  test('delegates removal to the repository', () async {
    final result = await useCase();

    expect(result.isSuccess, isTrue);
    expect(repository.removeCalled, isTrue);
  });

  test('propagates a repository failure', () async {
    repository.shouldFail = true;

    final result = await useCase();

    expect(result.failureOrNull, isA<DatabaseFailure>());
    expect(repository.removeCalled, isTrue);
  });
}
