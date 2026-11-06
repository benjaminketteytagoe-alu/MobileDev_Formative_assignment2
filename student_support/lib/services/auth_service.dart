import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/user_model.dart';
import '../utils/error_messages.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String studentDomain = '@alustudent.com';
  static const String staffDomain = '@alueducation.com';

  /// OAuth "Web client" from google-services.json (client_type 3). Android
  /// needs it to get an ID token that Firebase accepts.
  static const String googleServerClientId =
      '631219479011-v1fd4hvu3qimuoqkua3mme6gpikt204m.apps.googleusercontent.com';

  bool _googleReady = false;

  /// Emits on sign-in, sign-out and on profile changes such as a reload
  /// after the user verifies their email.
  Stream<User?> get userChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Returns the role that matches the email domain, or null for any other
  /// domain. Accounts outside the two university domains are not allowed.
  static UserRole? roleForEmail(String email) {
    final lower = email.trim().toLowerCase();
    if (lower.endsWith(staffDomain)) return UserRole.staff;
    if (lower.endsWith(studentDomain)) return UserRole.student;
    return null;
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalisedEmail = email.trim().toLowerCase();
    final role = roleForEmail(normalisedEmail);
    if (role == null) {
      throw const AppException(
        'Use your @alustudent.com or @alueducation.com email address.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalisedEmail,
      password: password,
    );
    final firebaseUser = credential.user!;

    final user = UserModel(
      id: firebaseUser.uid,
      name: name.trim(),
      email: normalisedEmail,
      role: role,
    );

    try {
      await _userDoc(firebaseUser.uid).set(user.toJson());
    } catch (e) {
      // The profile is created again on the next sign-in if this fails.
      debugPrint('Could not create user document: $e');
    }

    // Updating the display name triggers userChanges, which makes the auth
    // provider re-read the profile document that now exists.
    await firebaseUser.updateDisplayName(user.name);

    if (role == UserRole.staff) {
      await _sendVerificationQuietly(firebaseUser);
    }

    return credential;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    await _ensureUserDocument(credential.user!);
    return credential;
  }

  /// Signs in with a Google account. Only the two university domains are
  /// accepted, the same rule as email sign-up. Returns null if the user
  /// closes the account picker.
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final credential = await _auth.signInWithPopup(GoogleAuthProvider());
      return _acceptGoogleUser(credential);
    }

    await _initGoogle();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    // Check the domain before Firebase sees the account, so no Auth user is
    // created for an outside address.
    if (roleForEmail(account.email) == null) {
      await _signOutGoogleQuietly();
      throw const AppException(
        'Use your @alustudent.com or @alueducation.com Google account.',
      );
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AppException('Google did not return a sign-in token.');
    }
    final credential = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    return _acceptGoogleUser(credential);
  }

  Future<UserCredential> _acceptGoogleUser(UserCredential credential) async {
    final user = credential.user!;
    if (roleForEmail(user.email ?? '') == null) {
      // Web popups cannot be filtered up front, so reject here instead.
      await logout();
      throw const AppException(
        'Use your @alustudent.com or @alueducation.com Google account.',
      );
    }
    await _ensureUserDocument(user);
    return credential;
  }

  Future<void> _initGoogle() async {
    if (_googleReady) return;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    await GoogleSignIn.instance.initialize(
      clientId: isIos ? DefaultFirebaseOptions.ios.iosClientId : null,
      serverClientId: googleServerClientId,
    );
    _googleReady = true;
  }

  Future<void> _signOutGoogleQuietly() async {
    if (kIsWeb || !_googleReady) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Could not sign out of Google: $e');
    }
  }

  /// Signs out of Firebase and of Google, so the account picker shows again
  /// next time.
  Future<void> logout() async {
    await _signOutGoogleQuietly();
    await _auth.signOut();
  }

  /// Reads the profile of the signed-in user, or null if it does not exist.
  Future<UserModel?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final doc = await _userDoc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.id, doc.data()!);
  }

  Future<void> updateProfile({required String name}) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _userDoc(userId).update({'name': name.trim()});
  }

  Future<void> resendVerificationEmail() async {
    final user = currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
  }

  /// Reloads the user from Firebase and forces a fresh ID token, so the
  /// security rules see the new email_verified value straight away.
  Future<bool> refreshVerificationStatus() async {
    final user = currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = _auth.currentUser;
    await refreshed?.getIdToken(true);
    return refreshed?.emailVerified ?? false;
  }

  /// Creates the profile document if sign-up could not write it.
  Future<void> _ensureUserDocument(User firebaseUser) async {
    try {
      final doc = await _userDoc(firebaseUser.uid).get();
      if (doc.exists) return;
      final email = (firebaseUser.email ?? '').toLowerCase();
      final role = roleForEmail(email);
      if (role == null) return;
      await _userDoc(firebaseUser.uid).set(
        UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@').first,
          email: email,
          role: role,
        ).toJson(),
      );
    } catch (e) {
      debugPrint('Could not verify user document: $e');
    }
  }

  Future<void> _sendVerificationQuietly(User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('Could not send verification email: $e');
    }
  }

  /// Sends a password reset email to the given address.
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }
}
