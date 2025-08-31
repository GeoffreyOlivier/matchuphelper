import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'services/openai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ DEBUG: dotenv load failed or .env missing/empty: $e');
  }
  // Initialize Firebase (uses platform config files: GoogleService-Info.plist / google-services.json)
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
    // Ensure we have an authenticated session (anonymous) for Firebase Storage rules
    await FirebaseAuth.instance.signInAnonymously();
    // ignore: avoid_print
    print('✅ DEBUG: Firebase initialized and anonymous sign-in succeeded');
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ DEBUG: Firebase initialization failed: $e');
    print('⚠️ DEBUG: Cloud upload will be skipped. Place GoogleService-Info.plist (iOS) and google-services.json (Android).');
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
