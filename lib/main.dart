// ignore: unused_import
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
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
    return const MaterialApp(
      title: 'Flutter connection iu',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  } 
}






















