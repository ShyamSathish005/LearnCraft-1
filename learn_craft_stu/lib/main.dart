import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:learn_craft_stu/screens/profile/ProfileScreen.dart';
import 'package:learn_craft_stu/screens/study_path/study_path_screen.dart';
import 'screens/authentication_screens/login_screen.dart';
import 'screens/authentication_screens/register_screen.dart';
import 'screens/authentication_screens/user_details_screen.dart';
import 'screens/chat_screens/chat_screen.dart'; // Original ChatScreen with messages
import 'screens/intro_screens/splash_screen.dart';
import 'debug/debug_menu.dart';
import 'screens/chat_screens/quiz_screen.dart'; // Contains TeachScreen

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Filter debugPrint to show only Gemini-specific messages
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      if (message.contains('Gemini:') || message.contains('Gemini Error:')) {
        print(message); // Output only Gemini-related messages
      }
    }
  };

  // Initialize Firebase for web and mobile
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
      apiKey: 'AIzaSyBP9rGTu7EaiNuzyvuC7FFzA0hHte4Wpzk',
      appId: '1:346433396765:web:284a9ef71156c50013a6f4',
      messagingSenderId: '346433396765',
      projectId: 'learncraft-5145',
      authDomain: 'learncraft-5145.firebaseapp.com',
      storageBucket: 'learncraft-5145.firebasestorage.app',
      measurementId: 'G-J2LMDXMYJX',
    )
        : DefaultFirebaseOptions.currentPlatform, // Use generated options for mobile (Android/iOS)
  );

  runApp(const MyApp());
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
        '/': (context) => const SplashScreen(), // Splash screen as the initial route
        '/login': (context) => const LoginScreen(), // Login screen
        '/register': (context) => const RegisterScreen(), // Register screen
        '/user-details': (context) => const UserDetailsScreen(), // User details screen
        '/chat': (context) => const ChatScreen(), // Chat screen with messages
        '/debug': (context) => const DebugMenu(), // Debug menu screen
        '/profile': (context) => const ProfileScreen(), // Profile screen
        '/quiz': (context) => const TeachScreen(),
        '/path': (context) => const StudyPathScreen(),
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