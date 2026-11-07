import '../core/alu_email.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Detects the role from the email domain
  static String? detectRoleFromEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower.endsWith(AluEmail.studentDomain)) return 'student';
    if (lower.endsWith(AluEmail.staffDomain)) return 'staff';
    return null;
  }

  /// Checks if the email domain is valid for either role
  static bool isValidDomain(String? value) {
    if (value == null || value.isEmpty) return false;
    final lower = value.toLowerCase();
    return lower.endsWith(AluEmail.studentDomain) ||
        lower.endsWith(AluEmail.staffDomain);
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? minLength(String? value, int length, [String? fieldName]) {
    if (value == null || value.trim().length < length) {
      return '${fieldName ?? 'This field'} must be at least $length characters';
    }
    return null;
  }

  static String? maxLength(String? value, int length, [String? fieldName]) {
    if (value != null && value.trim().length > length) {
      return '${fieldName ?? 'This field'} must be at most $length characters';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
