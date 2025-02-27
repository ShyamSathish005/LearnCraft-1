import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:learn_craft_stu/screens/profile/ProfileScreen.dart';
import 'screens/authentication_screens/login_screen.dart';
import 'screens/authentication_screens/register_screen.dart';
import 'screens/authentication_screens/user_details_screen.dart';
import 'screens/chat_screens/chat_screen.dart';
import 'screens/intro_screens/splash_screen.dart';
import 'debug/debug_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with web-specific configuration if on web
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "your-api-key",
          authDomain: "your-project-id.firebaseapp.com",
          projectId: "your-project-id",
          storageBucket: "your-project-id.appspot.com",
          messagingSenderId: "your-messaging-sender-id",
          appId: "your-app-id",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }

    // Optional: Activate App Check for web and mobile
    await FirebaseAppCheck.instance.activate(
      // For web, you might need to configure App Check separately
      webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'), // Replace with your reCAPTCHA v3 site key
    );

    // Optional: Use Firestore Emulator for local testing (comment out or remove for production)
    // if (!kIsWeb) {
    //   await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    // }

    runApp(MyApp());
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
    // Handle initialization failure (e.g., show an error screen or exit)
    runApp(ErrorApp(errorMessage: "Failed to initialize Firebase: $e"));
  }
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
        '/user-details': (context) => UserDetailsScreen(), // User details screen
        '/chat': (context) => ChatScreen(), // Chat screen
        '/debug': (context) => DebugMenu(), // Debug menu screen
        '/profile': (context) => ProfileScreen(), // Profile screen
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

// Error screen as a fallback if Firebase initialization fails
class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp({required this.errorMessage, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            errorMessage,
            style: TextStyle(fontFamily: 'Poppins', color: Colors.red),
          ),
        ),
      ),
    );
  }
}