import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'screens/home_screen.dart';
import 'services/openai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // dotenv load failed; proceed without .env
  }
  // Initialize Firebase (uses platform config files: GoogleService-Info.plist / google-services.json)
  try {
    await Firebase.initializeApp();
    // Enable App Check with debug providers to suppress warnings in dev/testing
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (_) {
      // App Check activation failed; continue without it
    }
    // Ensure we have an authenticated session (anonymous) for Firebase Storage rules
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    // Firebase initialization failed; cloud upload will be skipped.
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => OpenAIService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoL Matchup Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E86D4),
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF0a142a),
          background: const Color(0xFF050d1c),
        ),
        scaffoldBackgroundColor: const Color(0xFF0a142a),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.copyWith(
          displayLarge: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          displayMedium: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          displaySmall: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          headlineLarge: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          headlineMedium: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          headlineSmall: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          titleLarge: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          titleMedium: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
          titleSmall: const TextStyle(fontFamily: 'Beaufort', fontWeight: FontWeight.w800),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
