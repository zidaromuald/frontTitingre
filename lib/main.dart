// ignore: unused_import
import 'package:flutter/material.dart';
import 'loginScreen.dart';

void main() {
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






















