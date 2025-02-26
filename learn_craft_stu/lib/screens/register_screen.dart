import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;

  void register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().registerUser(
        emailController.text,
        passwordController.text,
        "User Name", // Placeholder for name
      );

      if (user != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text("Verify Your Email"),
            content: Text("A verification email has been sent to ${emailController.text}. Please verify your email before logging in."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
        _checkEmailVerification();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed. Please try again.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                    "Create Account",
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
                    "Create an account so you can explore all the existing jobs",
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
                  SizedBox(height: 15),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue[900]!),
                      ),
                      filled: true,
                      fillColor: Colors.blue[50],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Already have an account",
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