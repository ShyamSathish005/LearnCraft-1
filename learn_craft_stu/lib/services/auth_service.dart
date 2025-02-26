import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> registerUser(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Store user data in Firestore
        await _firestore.collection("users").doc(user.uid).set({
          "name": name,
          "email": email,
          "uid": user.uid,
          "firstLogin": true, // Track first login for password change
          "isVerified": false, // Track email verification status
        });

        return user;
      }
      return null;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Check if email is verified
        if (!user.emailVerified) {
          await user.sendEmailVerification(); // Resend verification if not verified
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before logging in.',
          );
        }

        // Check if this is the first login and redirect to password change if needed
        final userDoc = await _firestore.collection("users").doc(user.uid).get();
        if (userDoc.exists && userDoc.data()?['firstLogin'] == true) {
          // Navigate to password change screen (implement this screen later)
          throw FirebaseAuthException(
            code: 'first-login',
            message: 'Please change your password before proceeding.',
          );
        }

        return user;
      }
      return null;
    } catch (e) {
      print("Error: $e");
      if (e is FirebaseAuthException) {
        rethrow; // Let the caller handle specific errors
      }
      return null;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // Method to resend verification email
  Future<void> resendVerificationEmail(String email) async {
    User? user = _auth.currentUser;
    if (user != null && user.email == email) {
      await user.sendEmailVerification();
    }
  }

  // Method to check if email is verified
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Refresh user data
      return user.emailVerified;
    }
    return false;
  }

  // Method to update password on first login (to be called from a password change screen)
  Future<void> updatePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
      await _firestore.collection("users").doc(user.uid).update({
        "firstLogin": false, // Mark first login as complete
      });
    }
  }
}