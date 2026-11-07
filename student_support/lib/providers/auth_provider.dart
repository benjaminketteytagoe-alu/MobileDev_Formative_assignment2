import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({this.status = AuthStatus.loading, this.user, this.error});

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// The security rules apply the same check, so this only controls what the
  /// UI shows.
  bool get isStaff => isAuthenticated && user?.role == UserRole.staff;

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.userChanges.asyncMap((firebaseUser) async {
    if (firebaseUser == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    UserModel? profile;
    try {
      profile = await service.getCurrentUser();
    } catch (_) {
      // Offline or Firestore unavailable. Fall back to Auth data below.
    }

    return AuthState(
      status: AuthStatus.authenticated,
      user: profile ?? UserModel.fromFirebaseUser(firebaseUser),
    );
  });
});
