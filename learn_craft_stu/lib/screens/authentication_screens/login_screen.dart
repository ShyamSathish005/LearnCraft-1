import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../chat_screens/chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController = TextEditingController(); // For email or username
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    if (identifierController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter an identifier and password")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final String identifier = identifierController.text.trim();
      String? email;

      debugPrint("Querying Firestore for identifier: $identifier");

      // First, try to log in with the identifier as an email
      try {
        final user = await AuthService().loginUser(identifier, passwordController.text);
        if (user != null) {
          debugPrint("User logged in with email: $identifier");
          if (user.emailVerified) {
            Navigator.pushReplacementNamed(context, '/chat'); // Navigate to ChatScreen if verified
          } else {
            _showVerificationDialog();
          }
          return;
        }
      } catch (e) {
        // If login fails, proceed to find by username
      }

      // If login with email fails, query Firestore to find by username, retrieving only email and username
      final QuerySnapshot usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: identifier)
          .limit(1)
          .get({ 'email', 'username' } as GetOptions?); // Retrieve only email and username fields

      if (usernameQuery.docs.isEmpty) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'No user found with that email or username');
      }

      email = usernameQuery.docs.first['email'] as String?;
      if (email == null || email.isEmpty) {
        throw Exception("Email not found for user");
      }

      debugPrint("Found user by username, email: $email");

      // Now, try to log in with the retrieved email
      final user = await AuthService().loginUser(email, passwordController.text);
      if (user != null) {
        debugPrint("User logged in with username: $identifier, email: $email");
        if (user.emailVerified) {
          Navigator.pushReplacementNamed(context, '/chat'); // Navigate to ChatScreen if verified
        } else {
          _showVerificationDialog();
        }
      } else {
        throw Exception("Login failed with retrieved email");
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Invalid email/username or password";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with that email or username";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password";
      }
      debugPrint("Login error (FirebaseAuth): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } on FirebaseException catch (e) {
      debugPrint("Login error (Firebase/Firestore): $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showVerificationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Email Not Verified"),
        content: Text("Please verify your email before logging in. Would you like to resend the verification email?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await AuthService().resendVerificationEmail(identifierController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Verification email resent. Please check your inbox.")),
              );
              _checkEmailVerification();
            },
            child: Text("Resend"),
          ),
        ],
      ),
    );
  }

  void _checkEmailVerification() async {
    while (true) {
      await Future.delayed(Duration(seconds: 3));
      bool isVerified = await AuthService().isEmailVerified();
      debugPrint("Checking email verification: $isVerified");
      if (isVerified) {
        try {
          final user = await AuthService().loginUser(identifierController.text, passwordController.text);
          if (user != null) {
            debugPrint("Email verified, navigating to ChatScreen");
            Navigator.pushReplacementNamed(context, '/chat'); // Navigate to ChatScreen
          }
        } catch (e) {
          debugPrint("Login after verification error: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed after verification. Please try again: $e")),
          );
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Login here",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Welcome back you've been missed!",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  TextField(
                    controller: identifierController,
                    decoration: InputDecoration(
                      hintText: "Email or Username",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue[900]!),
                      ),
                      filled: true,
                      fillColor: Colors.blue[50],
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue[900]!),
                      ),
                      filled: true,
                      fillColor: Colors.blue[50],
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Forgot password feature coming soon!")),
                        );
                      },
                      child: Text(
                        "Forgot your password?",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Sign in",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register'); // Use named route for RegisterScreen
                    },
                    child: Text(
                      "Create new account",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.blue[900],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Or continue with",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.g_mobiledata, color: Colors.black),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Google login coming soon!")),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.facebook, color: Colors.black),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Facebook login coming soon!")),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.apple, color: Colors.black),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Apple login coming soon!")),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}