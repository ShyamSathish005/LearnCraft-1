import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LearnCraft',
      theme: ThemeData(
        primaryColor: Colors.white, // White background
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.blue[900]), // Blue accents
        fontFamily: 'Poppins', // Default to Poppins
        scaffoldBackgroundColor: Colors.white,
      ),
      home: SplashScreen(),
    );
  }
}