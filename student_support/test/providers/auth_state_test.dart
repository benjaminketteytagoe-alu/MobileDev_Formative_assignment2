import 'package:flutter_test/flutter_test.dart';
import 'package:student_support/models/user_model.dart';
import 'package:student_support/providers/auth_provider.dart';

void main() {
  UserModel user(UserRole role) =>
      UserModel(id: 'u1', name: 'Test', email: 'test@x.com', role: role);

  group('AuthState role checks', () {
    test('a staff account is staff', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: user(UserRole.staff),
      );
      expect(state.isStaff, isTrue);
    });

    test('a student is never staff', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: user(UserRole.student),
      );
      expect(state.isStaff, isFalse);
    });

    test('a signed-out state is neither', () {
      const state = AuthState(status: AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.isStaff, isFalse);
    });
  });
}
