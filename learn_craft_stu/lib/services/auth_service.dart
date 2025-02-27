import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> registerUser(String email, String password, String name) async {
    try {
      debugPrint("Creating user with email: $email");
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        debugPrint("Verification email sent to: ${user.email}");
      }
      return user;
    } catch (e) {
      debugPrint("Auth error: $e");
      throw e; // Re-throw the exception for handling in the UI
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      debugPrint("Logging in user with email: $email");
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Auth login error: $e");
      throw e; // Re-throw the exception for handling in the UI
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      debugPrint("Resending verification email for: $email");
      final List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        final User? user = _auth.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          debugPrint("Verification email resent to: ${user.email}");
        }
      }
    } catch (e) {
      debugPrint("Error resending verification email: $e");
      throw e; // Re-throw the exception for handling in the UI
    }
  }

  Future<bool> isEmailVerified() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Refresh user data
      debugPrint("Email verification status: ${user.emailVerified}");
      return user.emailVerified;
    }
    return false;
  }
}