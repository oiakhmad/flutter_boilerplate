import 'package:flutter_clean_boilerplate/core/error/failure.dart';
import 'package:flutter_clean_boilerplate/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('success exposes value and no failure', () {
      const result = Result<int>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('failure exposes failure and no value', () {
      const failure = UnexpectedFailure('boom');
      const result = Result<int>.failure(failure);

      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
    });

    test('fold calls the matching branch', () {
      const success = Result<int>.success(10);
      const failure = Result<int>.failure(UnexpectedFailure());

      expect(success.fold((f) => -1, (v) => v * 2), 20);
      expect(failure.fold((f) => -1, (v) => v * 2), -1);
    });

    test('map transforms a success and passes through a failure', () {
      const success = Result<int>.success(3);
      const failure = Result<int>.failure(UnexpectedFailure('nope'));

      expect(success.map((v) => v + 1).valueOrNull, 4);
      expect(failure.map((v) => v + 1).failureOrNull, const UnexpectedFailure('nope'));
    });
  });
}
