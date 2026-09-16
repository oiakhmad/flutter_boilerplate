/// Pure, stateless validation helpers.
///
/// These are generic rules (non-empty, email shape, length bounds) with no
/// knowledge of any specific entity. Feature-specific business rules (e.g.
/// "an Account must have a name and email") are assembled from these
/// primitives inside the relevant use case, not here - this file must stay
/// free of feature/domain knowledge.
abstract final class Validators {
  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
  );

  static bool isNotBlank(String value) => value.trim().isNotEmpty;

  static bool hasMinLength(String value, int min) =>
      value.trim().length >= min;

  static bool hasMaxLength(String value, int max) =>
      value.trim().length <= max;

  static bool isValidEmail(String value) =>
      _emailPattern.hasMatch(value.trim());
}
