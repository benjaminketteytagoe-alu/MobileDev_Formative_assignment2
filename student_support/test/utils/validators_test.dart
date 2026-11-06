import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/utils/validators.dart';

void main() {
  group('Validators.detectRoleFromEmail', () {
    test('a student address gives the student role', () {
      expect(Validators.detectRoleFromEmail('jane@alustudent.com'), 'student');
    });

    test('a staff address gives the staff role', () {
      expect(Validators.detectRoleFromEmail('jane@alueducation.com'), 'staff');
    });

    test('an outside address gives no role', () {
      expect(Validators.detectRoleFromEmail('jane@gmail.com'), isNull);
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
