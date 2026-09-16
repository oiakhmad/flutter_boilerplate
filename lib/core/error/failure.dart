import 'package:equatable/equatable.dart';

/// Base type for every recoverable error that can cross a layer boundary.
///
/// Data sources throw raw exceptions (e.g. [DatabaseException]); repository
/// implementations are responsible for catching those and translating them
/// into a [Failure] before returning a [Result]. Presentation code only
/// ever sees a [Failure], never a raw database/platform exception.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// A developer-readable message (not user-facing copy - the presentation
  /// layer maps [Failure] subtype to a localized string via
  /// `context.l10n`).
  final String message;

  @override
  List<Object?> get props => [runtimeType, message];
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(this.fieldErrors)
      : super('One or more fields are invalid');

  /// Field name -> validation message key, so the presentation layer can
  /// highlight the exact field without re-deriving the rule.
  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [runtimeType, fieldErrors];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network operation failed']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Requested resource not found']);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred']);
}
