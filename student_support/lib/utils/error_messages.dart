import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

/// An error whose message is already written for the user.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Turns any error thrown by Firebase or the app into a sentence a user can act on.
String describeError(Object error) {
  if (error is AppException) return error.message;

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Sign in instead.';
      case 'weak-password':
        return 'Choose a stronger password of at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'account-exists-with-different-credential':
        return 'This email already uses a password. Sign in with your password instead.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled yet. Ask the administrator to enable it in Firebase.';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';
    }
    return error.message ?? 'Authentication failed.';
  }

  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        return 'Google sign-in was cancelled.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign-in is not set up for this build yet. '
            'Add the app\'s SHA-1 fingerprint in Firebase.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in is not available on this device.';
      default:
        return 'Google sign-in failed. Please try again.';
    }
  }

  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
      case 'unauthorized':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'The service is unavailable. Check your connection and try again.';
      case 'failed-precondition':
        return 'The database is missing an index. Ask the administrator to deploy the Firestore indexes.';
      case 'canceled':
        return 'The upload was cancelled.';
    }
    return error.message ?? 'Something went wrong. Please try again.';
  }

  if (error is StorageException) {
    switch (error.statusCode) {
      case '401':
      case '403':
        return 'You do not have permission to upload this photo.';
      case '413':
        return 'This photo is too large. The limit is 5 MB.';
      case '415':
        return 'Only image files can be uploaded.';
    }
    return 'The photo service could not be reached. Try again.';
  }

  return 'Something went wrong. Please try again.';
}
