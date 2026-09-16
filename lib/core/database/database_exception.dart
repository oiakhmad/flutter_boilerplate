/// Thrown by [LocalDatabase]/[DatabaseStore] on any storage failure.
///
/// This is the only exception type the data layer should let escape from
/// database code. Repository implementations catch it and translate it
/// into a [DatabaseFailure] before returning a [Result] to the domain
/// layer - callers above the data layer never see this type.
class DatabaseException implements Exception {
  const DatabaseException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'DatabaseException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}
