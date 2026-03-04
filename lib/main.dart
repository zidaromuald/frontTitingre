// ignore: unused_import
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'loginScreen.dart';

void main() async {
  // Assurer que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase - COMMENTÉ TEMPORAIREMENT (fichiers de config manquants)
  // await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Titingre',
      debugShowCheckedModeBanner: false,
      // Force le mode clair sur mobile - évite que ThemeData.dark() rende
      // les textes blancs sur fond blanc (textes invisibles en mode sombre système)
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E4A8C),
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}






















