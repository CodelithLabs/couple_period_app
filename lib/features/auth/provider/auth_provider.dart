import 'package:couple_period_app/features/auth/model/app_user.dart';
import 'package:couple_period_app/features/auth/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final googleSignInProvider = Provider<GoogleSignIn>(
  (_) => GoogleSignIn(scopes: const ['email', 'profile']),
);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final appUserProvider = StreamProvider<AppUser?>((ref) {
  return ref
      .watch(authServiceProvider)
      .authStateChanges()
      .map(
        (firebaseUser) =>
            firebaseUser == null ? null : AppUser.fromFirebase(firebaseUser),
      );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authServiceProvider));
    });

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._authService) : super(const AsyncData(null));

  final AuthService _authService;

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_authService.signInWithGoogle);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_authService.signOut);
  }
}
