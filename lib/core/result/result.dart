import 'package:flutter_clean_boilerplate/core/error/failure.dart';

/// A lightweight, exhaustive Success/Failure wrapper.
///
/// Every repository and use case in this project returns `Result<T>`
/// instead of throwing. Presentation code should never need a try/catch
/// around a call into the domain layer - failures are values, not
/// exceptions. This is a hand-rolled type rather than a dependency on a
/// functional-programming package: the shape needed here (map / fold /
/// isSuccess) is small enough not to justify an extra dependency.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;

  /// Returns the success value, or `null` if this is a failure.
  T? get valueOrNull => switch (this) {
        Success<T>(value: final v) => v,
        ResultFailure<T>() => null,
      };

  /// Returns the failure, or `null` if this is a success.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        ResultFailure<T>(failure: final f) => f,
      };

  /// Collapses both branches into a single value of type [R].
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    return switch (this) {
      Success<T>(value: final v) => onSuccess(v),
      ResultFailure<T>(failure: final f) => onFailure(f),
    };
  }

  /// Transforms the success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final v) => Result<R>.success(transform(v)),
      ResultFailure<T>(failure: final f) => Result<R>.failure(f),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final Failure failure;
}
