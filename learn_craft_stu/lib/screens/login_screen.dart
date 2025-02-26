import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().loginUser(emailController.text, passwordController.text);
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-not-verified') {
        _showVerificationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid email or password")),
        );
      }
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
              await AuthService().resendVerificationEmail(emailController.text);
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
      if (isVerified) {
        try {
          final user = await AuthService().loginUser(emailController.text, passwordController.text);
          if (user != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ChatScreen()),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login failed after verification. Please try again.")),
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
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
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
                  Text(
                    "Create new account",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.blue[900],
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
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