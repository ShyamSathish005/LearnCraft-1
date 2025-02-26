import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Brain icon and related elements (you can use an image asset or SVG)
              Image.asset(
                'assets/brain_icon.png', // Add this to pubspec.yaml under assets
                height: 200,
                width: 200,
              ),
              SizedBox(height: 20),
              Text(
                'Discover Your Learning Path',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Explore all the existing study paths based on your interest and learning style',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
              ),
              SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                },
                child: Text(
                  'Register',
                  style: GoogleFonts.poppins(color: Colors.blue[900]!, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}