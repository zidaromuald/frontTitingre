import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';
import 'package:gestauth_clean/iu/HomePage.dart';
import 'package:gestauth_clean/is/AccueilPage.dart';
import 'package:gestauth_clean/loginScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Petit délai pour afficher le splash screen
    await Future.delayed(const Duration(seconds: 2));

    final isAuthenticated = await AuthBaseService.isAuthenticated();

    if (!mounted) return;

    if (isAuthenticated) {
      // L'utilisateur a un token sauvegardé, vérifier le type
      final userType = await AuthBaseService.getUserType();

      if (!mounted) return;

      if (userType == 'societe') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccueilPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      // Pas de token, aller au login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou nom de l'app
            Text(
              'Titingre',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
