// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/auth_check_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/login_screen.dart';
// For formatting DateTime

// Ensure you have these dependencies in your pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   firebase_core: ^2.27.1 # Or latest
//   firebase_auth: ^4.17.9 # Or latest
//   google_sign_in: ^6.2.1 # Or latest
//   cloud_firestore: ^4.15.9 # Or latest
//   intl: ^0.19.0 # Or latest

// You'll also need to configure Firebase for your Flutter project.
// Refer to the official Firebase documentation for Flutter:
// https://firebase.google.com/docs/flutter/setup

// You will need to replace the placeholder values below with your actual
// Firebase project's web configuration. You can find these details in your
// Firebase project settings under "Web apps".
const firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyCThyf7zYBZjueYOZB3AL-Cu41FFFpxatk",
  authDomain: "realtimebus-c61cd.firebaseapp.com",
  projectId: "realtimebus-c61cd",
  storageBucket: "realtimebus-c61cd.firebasestorage.app",
  messagingSenderId: "518519944522",
  appId: "1:518519944522:web:f1b3b79e0f0444bc10fdb3",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: kIsWeb ? firebaseOptions : null,
    );
    runApp(const MyApp());
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Show some error UI
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Auth App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

