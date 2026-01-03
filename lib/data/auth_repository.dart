import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/auth_exception.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      // Update display name
      await userCredential.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  AuthException _handleFirebaseAuthError(FirebaseAuthException e) {
    if (e.code == 'network-request-failed') {
      return AuthException(
        'No internet connection. Please check your network.',
      );
    } else if (e.code == 'user-not-found' ||
        e.code == 'wrong-password' ||
        e.code == 'invalid-credential') {
      return AuthException('Invalid email or password.');
    } else if (e.code == 'email-already-in-use') {
      return AuthException(
        'The email address is already in use by another account.',
      );
    } else if (e.code == 'invalid-email') {
      return AuthException('The email address is badly formatted.');
    } else if (e.code == 'weak-password') {
      return AuthException('The password is too weak.');
    } else {
      return AuthException('Authentication failed. Please try again later.');
    }
  }
}
