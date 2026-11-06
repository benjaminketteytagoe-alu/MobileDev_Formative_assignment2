import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/utils/validators.dart';

void main() {
  group('Validators.roleBasedEmail', () {
    test('accepts a student address for the student role', () {
      expect(Validators.roleBasedEmail('jane@alustudent.com', 'student'), isNull);
    });

    test('rejects a staff address for the student role', () {
      expect(
        Validators.roleBasedEmail('jane@alueducation.com', 'student'),
        isNotNull,
      );
    });

    test('rejects a student address for the staff role', () {
      expect(
        Validators.roleBasedEmail('jane@alustudent.com', 'staff'),
        isNotNull,
      );
    });

    test('rejects an empty value', () {
      expect(Validators.roleBasedEmail('', 'student'), 'Email is required');
    });
  });

  group('Validators length checks', () {
    test('minLength ignores surrounding whitespace', () {
      expect(Validators.minLength('   short   ', 10), isNotNull);
      expect(Validators.minLength('long enough text', 10), isNull);
    });

    test('maxLength rejects values that are too long', () {
      expect(Validators.maxLength('a' * 121, 120), isNotNull);
      expect(Validators.maxLength('a' * 120, 120), isNull);
    });

    test('confirmPassword requires a match', () {
      expect(Validators.confirmPassword('abc123', 'abc124'), isNotNull);
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });
}
