import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:learn_craft_stu/screens/profile/ProfileScreen.dart';
import 'firebase_options.dart';
import 'screens/authentication_screens/login_screen.dart';
import 'screens/authentication_screens/register_screen.dart';
import 'screens/authentication_screens/user_details_screen.dart';
import 'screens/chat_screens/chat_screen.dart';
import 'screens/intro_screens/splash_screen.dart';
import 'debug/debug_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LearnCraft',
      initialRoute: '/', // Start with SplashScreen
      routes: {
        '/': (context) => SplashScreen(), // Splash screen as the initial route
        '/login': (context) => const LoginScreen(), // Login screen
        '/register': (context) => RegisterScreen(), // Register screen
        '/user-details': (context) => UserDetailsScreen(), // New user details screen
        '/chat': (context) => ChatScreen(), // Chat screen
        '/debug': (context) => DebugMenu(), // Debug menu screen
        '/profile': (context) => ProfileScreen(), // New profile screen
      },
      theme: ThemeData(
        primaryColor: Colors.white, // White background
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blue[900], // Blue accents
        ),
        fontFamily: 'Poppins', // Default to Poppins
        scaffoldBackgroundColor: Colors.white,

      ),
    );
  }
}