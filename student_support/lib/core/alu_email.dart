/// The ALU email domains allowed to use the app. firestore.rules and
/// storage.rules hold the same two domains, so change them together.
class AluEmail {
  AluEmail._();

  static const String studentDomain = '@alustudent.com';
  static const String staffDomain = '@alueducation.com';

  /// Shown when an address is outside both domains.
  static const String requirement =
      'Use your $studentDomain or $staffDomain email';

  static bool isStudent(String email) =>
      email.trim().toLowerCase().endsWith(studentDomain);

  static bool isStaff(String email) =>
      email.trim().toLowerCase().endsWith(staffDomain);
}
