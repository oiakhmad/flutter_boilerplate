import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/entities/account.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/repositories/account_repository.dart';
import 'package:flutter_clean_boilerplate/features/account/domain/usecases/save_account.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-rolled fake instead of a mocking framework/build_runner - the
/// interface is tiny and this keeps the dev-dependency list minimal
/// (rule 2 / rule 15: avoid dependencies that aren't earning their keep).
class _FakeAccountRepository implements AccountRepository {
  Account? saved;
  bool shouldFail = false;

  @override
  Future<Result<Account?>> getAccount() async => Result.success(saved);

  @override
  Future<Result<void>> saveAccount(Account account) async {
    if (shouldFail) return const Result.failure(DatabaseFailure('disk full'));
    saved = account;
    return const Result.success(null);
  }
}

void main() {
  late _FakeAccountRepository repository;
  late SaveAccountUseCase useCase;

  setUp(() {
    repository = _FakeAccountRepository();
    useCase = SaveAccountUseCase(repository);
  });

  test('rejects a blank name without touching the repository', () async {
    final result = await useCase(
      const SaveAccountParams(name: '', email: 'a@b.com'),
      existing: null,
    );

    expect(result.isFailure, isTrue);
    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['name'], 'validationNameRequired');
    expect(repository.saved, isNull);
  });

  test('rejects an invalid email', () async {
    final result = await useCase(
      const SaveAccountParams(name: 'Ada Lovelace', email: 'not-an-email'),
      existing: null,
    );

    final failure = result.failureOrNull as ValidationFailure;
    expect(failure.fieldErrors['email'], 'validationEmailInvalid');
  });

  test('creates a new account with a fresh createdAt/updatedAt', () async {
    final result = await useCase(
      const SaveAccountParams(name: 'Ada Lovelace', email: 'ada@example.com'),
      existing: null,
    );

    expect(result.isSuccess, isTrue);
    final account = result.valueOrNull!;
    expect(account.name, 'Ada Lovelace');
    expect(account.email, 'ada@example.com');
    expect(account.createdAt, account.updatedAt);
  });

  test('updating an existing account preserves createdAt', () async {
    final existing = Account(
      id: 'current_account',
      name: 'Old Name',
      email: 'old@example.com',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final result = await useCase(
      const SaveAccountParams(name: 'New Name', email: 'new@example.com'),
      existing: existing,
    );

    final account = result.valueOrNull!;
    expect(account.createdAt, DateTime(2024, 1, 1));
    expect(account.updatedAt.isAfter(existing.updatedAt), isTrue);
  });

  test('propagates a repository failure', () async {
    repository.shouldFail = true;

    final result = await useCase(
      const SaveAccountParams(name: 'Ada Lovelace', email: 'ada@example.com'),
      existing: null,
    );

    expect(result.failureOrNull, isA<DatabaseFailure>());
  });
}
