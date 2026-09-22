import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/create_account.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake, matching the pattern used by `save_account_test.dart`:
/// no mocking framework, no database.
class _FakeAccountRepository implements AccountRepository {
  Account? saved;
  int saveCalls = 0;
  bool shouldFail = false;

  @override
  Future<Result<Account?>> getAccount() async => Result.success(saved);

  @override
  Future<Result<void>> saveAccount(Account account) async {
    saveCalls++;
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    saved = account;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> removeAccount() async {
    saveCalls++;
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    saved = null;
    return const Result.success(null);
  }
}

void main() {
  late _FakeAccountRepository repository;
  late CreateAccountUseCase useCase;

  setUp(() {
    repository = _FakeAccountRepository();
    useCase = CreateAccountUseCase(repository);
  });

  test('rejects a blank name without touching the repository', () async {
    final result = await useCase(
      const CreateAccountParams(name: '   '),
      existing: null,
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['name'], 'validationNameRequired');
    expect(repository.saveCalls, 0);
    expect(repository.saved, isNull);
  });

  test('rejects a name shorter than the minimum length', () async {
    final result = await useCase(
      const CreateAccountParams(name: 'A'),
      existing: null,
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['name'], 'validationNameTooShort');
    expect(repository.saveCalls, 0);
  });

  test('creates the account from a name only', () async {
    final result = await useCase(
      const CreateAccountParams(name: '  Budi  '),
      existing: null,
    );

    expect(result.isSuccess, isTrue);
    final account = result.valueOrNull!;
    expect(account.name, 'Budi', reason: 'name is trimmed');
    expect(account.id, 'current_account');
    expect(account.createdAt, account.updatedAt);
    expect(repository.saveCalls, 1);
    expect(repository.saved, account);
  });

  test('never creates a second account when one already exists', () async {
    final existing = Account(
      id: 'current_account',
      name: 'Budi',
      email: '',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final result = await useCase(
      const CreateAccountParams(name: 'Someone Else'),
      existing: existing,
    );

    expect(result.valueOrNull, existing);
    expect(repository.saveCalls, 0, reason: 'nothing is written');
    expect(repository.saved, isNull);
  });

  test('propagates a repository failure', () async {
    repository.shouldFail = true;

    final result = await useCase(
      const CreateAccountParams(name: 'Budi'),
      existing: null,
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}
