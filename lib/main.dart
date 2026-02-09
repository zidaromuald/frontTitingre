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
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}






















