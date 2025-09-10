// ignore_for_file: prefer_const_constructors, unused_import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestauth/is/AccueilPage.dart';
import 'package:gestauth/is/InscriptionSPage.dart';
import 'package:gestauth/iu/HomePage.dart';
import 'package:gestauth/models/authSIns.dart';
import 'package:gestauth/iu/InscriptionUPage.dart';
import 'package:gestauth/models/authIns.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailOrPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validation améliorée pour l'email
  bool _isValidEmail(String input) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(input);
  }

  bool _isValidPhone(String input) {
    // Nettoyer l'input (retirer espaces, tirets, parenthèses)
    final cleanedInput = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Vérifier le format international avec indicatif
    // + suivi de 1 à 3 chiffres pour l'indicatif, puis 7 à 12 chiffres (plus réaliste)
    final internationalPattern = RegExp(r'^\+[1-9]\d{0,3}\d{7,12}$');

    // Vérifier le format local (pour les numéros sans indicatif)
    // 8 à 12 chiffres (plus strict et réaliste)
    final localPattern = RegExp(r'^\d{8,12}$');

    return internationalPattern.hasMatch(cleanedInput) ||
        localPattern.hasMatch(cleanedInput);
  }

  // Méthode pour afficher les messages
  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

// ALTERNATIVE: Version avec sélecteur de page pour tests
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulation du délai
    await Future.delayed(const Duration(seconds: 1));

    // Afficher un dialog pour choisir la page de destination
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Mode Test - Choisir la destination'),
            content: const Text('Vers quelle page voulez-vous naviguer ?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                  _showMessage('Navigation vers HomePage (TEST)');
                },
                child: const Text('Page Utilisateur'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AccueilPage()),
                  );
                  _showMessage('Navigation vers AccueilPage (TEST)');
                },
                child: const Text('Page Société'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      );
    }
  }

  // Logique de connexion améliorée
  /*Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final emailOrPhone = _emailOrPhoneController.text.trim();
    final password = _passwordController.text.trim();

    try {
      Map<String, dynamic>? response;

      // Déterminer le type d'authentification
      if (_isValidEmail(emailOrPhone)) {
        final authService = AuthService();
        response =
            await authService.login(emailOrPhone, password, _showMessage);
      } else if (_isValidPhone(emailOrPhone)) {
        final authService = AuthsService();
        response =
            await authService.login(emailOrPhone, password, _showMessage);
      } else {
        _showMessage('Format d\'email ou de téléphone invalide', isError: true);
        return;
      }

      // Traitement de la réponse
      if (response != null && response['status'] == true) {
        final userType = response['userType'] ?? '';

        if (userType == 'societe') {
          _showMessage('Société connectée avec succès');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AccueilPage()),
            );
          }
        } else if (userType == 'user') {
          _showMessage('Utilisateur connecté avec succès');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        } else {
          _showMessage('Type d\'utilisateur non reconnu', isError: true);
        }
      } else {
        final errorMessage = response?['message'] ?? 'Connexion échouée';
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      _showMessage('Une erreur est survenue. Veuillez réessayer.',
          isError: true);
      debugPrint('Exception lors de la connexion: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }*/

  // Widget pour le champ Email/Téléphone avec validation
  Widget _buildEmailOrPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email ou Numéro de Téléphone',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _emailOrPhoneController,
            keyboardType: TextInputType.text, // était emailAddress
            style: const TextStyle(color: Colors.black87),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est requis';
              }

              final trimmedValue = value.trim();

              // Vérifier email d'abord
              if (_isValidEmail(trimmedValue)) {
                return null; // Email valide
              }

              // Vérifier téléphone
              if (_isValidPhone(trimmedValue)) {
                return null; // Téléphone valide
              }

              return 'Format invalide.\nEmail: exemple@domain.com\nTéléphone: +226 01 02 03 04';
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(
                Icons.person,
                color: Color(0xff5ac18e),
              ),
              hintText: 'exemple@email.com ou +226 01 02 03 04', // CORRIGÉ
              hintStyle: TextStyle(color: Colors.black38),
              errorStyle: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour le champ mot de passe avec validation
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mot de passe',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.black87),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le mot de passe est requis';
              }
              if (value.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères';
              }
              return null;
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(
                Icons.lock,
                color: Color(0xff5ac18e),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xff5ac18e),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              hintText: 'Votre mot de passe',
              hintStyle: const TextStyle(color: Colors.black38),
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Bouton mot de passe oublié
  Widget _buildForgotPasswordButton() {
    return Container(
      alignment: Alignment.centerRight,
      // child: TextButton(
      //   onPressed: () {
      //     // Navigation vers la page de récupération de mot de passe
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (context) =>  ForgotPasswordPage()),
      //     );
      //   },
      //   child: const Text(
      //     "Mot de passe oublié ?",
      //     style: TextStyle(
      //       color: Colors.white,
      //       fontWeight: FontWeight.bold,
      //       fontSize: 14,
      //     ),
      //   ),
      // ),
    );
  }

  // Bouton de connexion amélioré
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff5ac18e),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff5ac18e)),
                ),
              )
            : const Text(
                'SE CONNECTER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Séparateur "ou"
  Widget _buildSeparator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Expanded(
          child: Divider(
            color: Colors.white,
            thickness: 1,
            height: 80,
            indent: 30,
            endIndent: 30,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'ou',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Colors.white,
            thickness: 1,
            height: 80,
            indent: 30,
            endIndent: 30,
          ),
        ),
      ],
    );
  }

  // Bouton créer compte utilisateur
  Widget _buildUserAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InscriptionUPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: const Text(
          "Créer un compte utilisateur",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Bouton créer compte société
  Widget _buildCompanyAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InscriptionSPage()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: const Text(
          "Créer un compte société",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x665ac18e),
                Color(0x995ac18e),
                Color(0xcc5ac18e),
                Color(0xff5ac18e),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Connectez-vous',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),
                    _buildEmailOrPhoneField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    _buildForgotPasswordButton(),
                    const SizedBox(height: 20),
                    _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildSeparator(),
                    const SizedBox(height: 20),
                    _buildUserAccountButton(),
                    const SizedBox(height: 15),
                    _buildCompanyAccountButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
