import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/authentication_screens/login_screen.dart';

class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      debugPrint("User logged out");
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint("Logout failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Debug Menu", style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                "Logout",
                style: TextStyle(fontFamily: 'Poppins', color: Colors.blue[900]),
              ),
              onTap: () => _logout(context),
            ),
            // Add more developer tools here as needed
          ],
        ),
      ),
    );
  }
}