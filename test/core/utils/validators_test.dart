import 'package:flutter_clean_boilerplate/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('trims and collapses repeated spaces without changing punctuation',
        () {
      expect(
        Validators.normalize("  Budi   Santoso  "),
        'Budi Santoso',
      );
      expect(
        Validators.normalize("  O'Connor  Anne-Marie  "),
        "O'Connor Anne-Marie",
      );
    });

    test('preserves internal newlines and tabs', () {
      expect(
        Validators.normalize('first line\n\tsecond line'),
        'first line\n\tsecond line',
      );
    });
  });

  group('validateName', () {
    for (final name in [
      'Akhmad Zulkarnain',
      "O'Connor",
      'Anne-Marie',
      'José',
      'PT. Maju Jaya',
    ]) {
      test('accepts $name', () {
        final result = Validators.validateName(name);

        expect(result.isValid, isTrue);
        expect(result.errorCode, isNull);
        expect(result.normalizedValue, name);
      });
    }

    test('normalizes surrounding and repeated spaces', () {
      final result = Validators.validateName('  Budi   Santoso  ');

      expect(result.normalizedValue, 'Budi Santoso');
    });

    for (final invalidName in [
      'A',
      '123',
      'Budi\nSantoso',
      'Budi\tSantoso',
      "' OR '1'='1",
      '" OR "1"="1',
      '<script>alert(1)</script>',
      r'../../../../etc/passwd',
      r'${7*7}',
      r'{{7*7}}',
      '<!-- test -->',
    ]) {
      test('rejects $invalidName', () {
        final result = Validators.validateName(invalidName);

        expect(result.isValid, isFalse);
        expect(result.normalizedValue, isNull);
        expect(result.errorCode, isNotNull);
      });
    }
  });

  group('validateEmail', () {
    for (final email in [
      'user@example.com',
      'first.last@example.com',
      'user+tag@example.com',
      'user_name@example-domain.com',
    ]) {
      test('accepts $email', () {
        final result = Validators.validateEmail(email);

        expect(result.isValid, isTrue);
        expect(result.normalizedValue, email);
      });
    }

    for (final invalidEmail in [
      'not-an-email',
      'user@',
      '@example.com',
      'user@@example.com',
      'user+tag@',
      'user @example.com',
      'user@example.com\nnext',
      'user@example.com;drop',
    ]) {
      test('rejects $invalidEmail', () {
        final result = Validators.validateEmail(invalidEmail);

        expect(result.isValid, isFalse);
        expect(result.normalizedValue, isNull);
        expect(result.errorCode, isNotNull);
      });
    }
  });

  group('validateText', () {
    test('preserves general punctuation and Unicode', () {
      const input =
          'José — A&B, C/D: 100% #1 (safe) . , \' " - _ / : ; ( ) & + % #';

      final result = Validators.validateText(input, allowMultiline: true);

      expect(result.isValid, isTrue);
      expect(result.normalizedValue, input);
    });

    test('allows newlines and tabs only in multiline context', () {
      final multiline = Validators.validateText(
        'first line\n\tsecond line',
        allowMultiline: true,
      );
      final singleLine = Validators.validateText('first line\nsecond line');

      expect(multiline.isValid, isTrue);
      expect(multiline.normalizedValue, 'first line\n\tsecond line');
      expect(singleLine.isValid, isFalse);
    });

    test('preserves repeated spaces in multiline text when requested', () {
      final result = Validators.validateText(
        '  first  line\n  second  line  ',
        allowMultiline: true,
      );

      expect(result.isValid, isTrue);
      expect(result.normalizedValue, 'first  line\n  second  line');
    });
  });
}
