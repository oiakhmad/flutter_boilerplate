import 'package:equatable/equatable.dart';

/// Result of validating one input value.
///
/// A result carries a normalized value only when validation succeeds. This
/// prevents callers from accidentally persisting a value that has not passed
/// its context-specific rules.
class InputValidationResult extends Equatable {
  const InputValidationResult.valid(String value)
      : isValid = true,
        errorCode = null,
        normalizedValue = value;

  const InputValidationResult.invalid(String code)
      : isValid = false,
        errorCode = code,
        normalizedValue = null;

  final bool isValid;

  /// A localization-friendly error code, never user-facing copy.
  final String? errorCode;

  /// The value that is safe to pass to the next layer, only when valid.
  final String? normalizedValue;

  @override
  List<Object?> get props => [isValid, errorCode, normalizedValue];
}

/// Pure, stateless validation helpers.
///
/// These are generic rules (non-empty, email shape, length bounds) with no
/// knowledge of any specific entity. Feature-specific business rules (e.g.
/// "an Account must have a name and email") are assembled from these
/// primitives inside the relevant use case, not here - this file must stay
/// free of feature/domain knowledge.
abstract final class Validators {
  static final RegExp _multipleSpaces = RegExp(r' {2,}');
  static final RegExp _leadingSpaces = RegExp(r'^ +');
  static final RegExp _trailingSpaces = RegExp(r' +$');

  // Unicode property escapes are enabled explicitly so accented and
  // non-ASCII letters remain valid where the field's context allows them.
  static final RegExp _namePattern = RegExp(
    r'''^[\p{L}\p{M}\p{Zs} .'’\-]+$''',
    unicode: true,
  );
  static final RegExp _nameLetterPattern = RegExp(
    r'\p{L}',
    unicode: true,
  );

  // The local part keeps the common, valid punctuation set. In particular,
  // '.', '+', '-' and '_' are data, not characters to silently remove.
  static final RegExp _emailPattern = RegExp(
    r'''^[\p{L}\p{N}\p{M}!#$%&'*+\-/=?^_`{|}~]+(?:\.[\p{L}\p{N}\p{M}!#$%&'*+\-/=?^_`{|}~]+)*@[\p{L}\p{N}](?:[\p{L}\p{N}\-]{0,61}[\p{L}\p{N}])?(?:\.[\p{L}\p{N}](?:[\p{L}\p{N}\-]{0,61}[\p{L}\p{N}])?)+$''',
    unicode: true,
  );

  /// Safely normalizes surrounding whitespace and, for single-line fields,
  /// repeated ASCII spaces. Internal newlines and tabs are never globally
  /// removed. Multiline callers can set [collapseSpaces] to `false` when
  /// repeated spaces are meaningful formatting.
  static String normalize(
    String input, {
    bool collapseSpaces = true,
  }) {
    var normalized = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (collapseSpaces) {
      normalized = normalized.replaceAll(_multipleSpaces, ' ');
    }
    return normalized
        .replaceFirst(_leadingSpaces, '')
        .replaceFirst(_trailingSpaces, '');
  }

  static bool isNotBlank(String value) => value.trim().isNotEmpty;

  static bool hasMinLength(String value, int min) => value.trim().length >= min;

  static bool hasMaxLength(String value, int max) => value.trim().length <= max;

  /// Validates a name without treating punctuation as a global threat.
  ///
  /// Unicode letters/marks, whitespace, apostrophes, hyphens, and periods are
  /// supported. Newlines, tabs, and other control characters are rejected
  /// because names are single-line values.
  static InputValidationResult validateName(
    String input, {
    int minLength = 2,
    int? maxLength,
  }) {
    if (_containsDisallowedControlCharacter(input, allowMultiline: false)) {
      return const InputValidationResult.invalid('validationNameInvalid');
    }

    final normalized = normalize(input);
    if (normalized.isEmpty) {
      return const InputValidationResult.invalid('validationNameRequired');
    }

    if (!_namePattern.hasMatch(normalized) ||
        !_nameLetterPattern.hasMatch(normalized)) {
      return const InputValidationResult.invalid('validationNameInvalid');
    }

    final length = normalized.runes.length;
    if (length < minLength) {
      return const InputValidationResult.invalid('validationNameTooShort');
    }
    if (maxLength != null && length > maxLength) {
      return const InputValidationResult.invalid('validationNameTooLong');
    }

    return InputValidationResult.valid(normalized);
  }

  /// Validates general text while preserving ordinary punctuation and
  /// Unicode. This is not an HTML sanitizer: Flutter `Text` does not interpret
  /// the input as markup, and future HTML output must be handled at that
  /// output boundary.
  static InputValidationResult validateText(
    String input, {
    int? maxLength,
    bool allowMultiline = false,
  }) {
    if (_containsDisallowedControlCharacter(
      input,
      allowMultiline: allowMultiline,
    )) {
      return const InputValidationResult.invalid(
        'validationTextInvalidCharacter',
      );
    }

    final normalized = normalize(
      input,
      collapseSpaces: !allowMultiline,
    );
    if (maxLength != null && normalized.runes.length > maxLength) {
      return const InputValidationResult.invalid('validationTextTooLong');
    }

    return InputValidationResult.valid(normalized);
  }

  static bool isValidEmail(String value) => validateEmail(value).isValid;

  /// Validates an email address without deleting valid address characters.
  static InputValidationResult validateEmail(String input) {
    if (_containsDisallowedControlCharacter(input, allowMultiline: false)) {
      return const InputValidationResult.invalid('validationEmailInvalid');
    }

    final normalized = normalize(input);
    if (normalized.isEmpty) {
      return const InputValidationResult.invalid('validationEmailRequired');
    }

    if (_containsWhitespace(normalized) ||
        normalized.runes.length > 254 ||
        !_emailPattern.hasMatch(normalized)) {
      return const InputValidationResult.invalid('validationEmailInvalid');
    }

    final atIndex = normalized.lastIndexOf('@');
    final localPart = normalized.substring(0, atIndex);
    if (localPart.runes.length > 64) {
      return const InputValidationResult.invalid('validationEmailInvalid');
    }

    return InputValidationResult.valid(normalized);
  }

  /// Boolean compatibility helpers for existing and simple call sites.
  static bool isValidName(
    String input, {
    int minLength = 2,
    int? maxLength,
  }) {
    return validateName(
      input,
      minLength: minLength,
      maxLength: maxLength,
    ).isValid;
  }

  static bool isValidText(
    String input, {
    int? maxLength,
    bool allowMultiline = false,
  }) {
    return validateText(
      input,
      maxLength: maxLength,
      allowMultiline: allowMultiline,
    ).isValid;
  }

  /// True when [value] contains ASCII digits only (no spaces, signs or
  /// other characters).
  static bool isDigitsOnly(String value) =>
      value.isNotEmpty && RegExp(r'^\d+$').hasMatch(value);

  /// True when the raw [value] has exactly [length] characters.
  static bool hasExactLength(String value, int length) {
    return value.length == length;
  }

  static bool _containsWhitespace(String value) {
    return RegExp(r'\s', unicode: true).hasMatch(value);
  }

  static bool _containsDisallowedControlCharacter(
    String value, {
    required bool allowMultiline,
  }) {
    for (final codePoint in value.runes) {
      final isLineBreak = codePoint == 0x0A ||
          codePoint == 0x0D ||
          codePoint == 0x2028 ||
          codePoint == 0x2029;
      if (isLineBreak) {
        if (!allowMultiline) return true;
        continue;
      }

      // Tabs are retained for multiline text; they are not valid in a
      // single-line value such as a name or email address.
      if (codePoint == 0x09) {
        if (!allowMultiline) return true;
        continue;
      }

      if (codePoint <= 0x1F || (codePoint >= 0x7F && codePoint <= 0x9F)) {
        return true;
      }
    }
    return false;
  }
}
