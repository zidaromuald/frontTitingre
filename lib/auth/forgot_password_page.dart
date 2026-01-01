import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:convert';
// import '../services/api_service.dart';

/// Page de réinitialisation du mot de passe avec Firebase Authentication
/// Processus en 3 étapes:
/// 1. Saisie du numéro de téléphone
/// 2. Vérification du code OTP (Firebase) - COMMENTÉ TEMPORAIREMENT
/// 3. Création du nouveau mot de passe (envoi au backend)
///
/// NOTE: Firebase Auth est commenté car les fichiers de configuration sont manquants
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Focus nodes pour les champs OTP
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  // États
  final int _currentStep = 0;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  // String? _verificationId;  // Commenté car Firebase est désactivé
  // int? _resendToken;         // Commenté car Firebase est désactivé

  // Firebase Auth - COMMENTÉ TEMPORAIREMENT
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // Couleurs
  static const Color primaryColor = Color(0xff5ac18e);
  static const Color darkGray = Color(0xff8D8D8D);

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valider le format du numéro de téléphone
  bool _isValidPhone(String input) {
    final cleanedInput = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Format international uniquement pour Firebase
    final internationalPattern = RegExp(r'^\+[1-9]\d{0,3}\d{7,12}$');
    return internationalPattern.hasMatch(cleanedInput);
  }

  /// Formater le numéro pour Firebase (format E.164) - COMMENTÉ TEMPORAIREMENT
  // String _formatPhoneForFirebase(String phone) {
  //   String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  //   if (!cleaned.startsWith('+')) {
  //     // Si pas d'indicatif, ajouter +226 (Burkina Faso par défaut)
  //     cleaned = '+226$cleaned';
  //   }
  //   return cleaned;
  // }

  /// Étape 1: Envoyer le code OTP via Firebase - COMMENTÉ TEMPORAIREMENT
  Future<void> _sendOTP() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // FIREBASE AUTH COMMENTÉ - Configuration manquante
    // Pour réactiver, décommenter le code ci-dessous et ajouter les fichiers de config Firebase

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase non configuré. Veuillez ajouter google-services.json'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    setState(() => _isLoading = false);

    /* CODE ORIGINAL FIREBASE - À DÉCOMMENTER APRÈS CONFIGURATION
    try {
      final phoneNumber = _formatPhoneForFirebase(_phoneController.text.trim());

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Vérification automatique réussie');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Erreur de vérification: ${e.message}');
          if (mounted) {
            String errorMessage = 'Erreur lors de la vérification du numéro';
            if (e.code == 'invalid-phone-number') {
              errorMessage = 'Le numéro de téléphone est invalide';
            } else if (e.code == 'too-many-requests') {
              errorMessage = 'Trop de tentatives. Réessayez plus tard';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Code OTP envoyé');
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code OTP envoyé avec succès'),
                backgroundColor: primaryColor,
              ),
            );

            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            setState(() => _currentStep = 1);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Timeout de récupération automatique');
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
    */
  }

  /// Étape 2: Vérifier le code OTP avec Firebase - COMMENTÉ TEMPORAIREMENT
  Future<void> _verifyOTP() async {
    if (!_otpFormKey.currentState!.validate()) return;

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le code complet à 6 chiffres'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // FIREBASE AUTH COMMENTÉ - Configuration manquante
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase non configuré. Veuillez ajouter google-services.json'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    setState(() => _isLoading = false);

    /* CODE ORIGINAL FIREBASE - À DÉCOMMENTER APRÈS CONFIGURATION
    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de vérification. Veuillez recommencer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (mounted && userCredential.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code vérifié avec succès'),
            backgroundColor: primaryColor,
          ),
        );

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentStep = 2;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur Firebase: ${e.code} - ${e.message}');
      String errorMessage = 'Code OTP invalide';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Le code saisi est incorrect';
      } else if (e.code == 'session-expired') {
        errorMessage = 'Le code a expiré. Veuillez en demander un nouveau';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
    */
  }

  /// Étape 3: Réinitialiser le mot de passe via le backend - COMMENTÉ TEMPORAIREMENT
  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // FIREBASE AUTH COMMENTÉ - Configuration manquante
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Firebase non configuré. Veuillez ajouter google-services.json'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    setState(() => _isLoading = false);

    /* CODE ORIGINAL FIREBASE - À DÉCOMMENTER APRÈS CONFIGURATION
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final String firebaseIdToken = await user.getIdToken() ?? '';
      if (firebaseIdToken.isEmpty) {
        throw Exception('Impossible de récupérer le token Firebase');
      }

      final response = await ApiService.post(
        '/auth/password-reset',
        {
          'firebaseIdToken': firebaseIdToken,
          'newPassword': _newPasswordController.text,
        },
      );

      if (response.statusCode == 200) {
        await _auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe réinitialisé avec succès'),
              backgroundColor: primaryColor,
              duration: Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de la réinitialisation');
      }
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    */
  }

  /// Renvoyer le code OTP
  Future<void> _resendOTP() async {
    // Relancer l'envoi du code
    _sendOTP();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mot de passe oublié',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            _buildProgressIndicator(),

            // Contenu des étapes
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPhoneStep(),
                  _buildOTPStep(),
                  _buildPasswordStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Indicateur de progression
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Étape 1: Saisie du numéro de téléphone
  Widget _buildPhoneStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.phone_android,
              size: 80,
              color: primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Entrez votre numéro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nous allons vous envoyer un code de vérification SMS sur votre numéro de téléphone',
              style: TextStyle(
                fontSize: 15,
                color: darkGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '+226 XX XX XX XX',
                helperText: 'Format international requis (ex: +226XXXXXXXX)',
                prefixIcon: const Icon(Icons.phone, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                if (!_isValidPhone(value)) {
                  return 'Format invalide. Utilisez le format international (+226...)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Envoyer le code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Étape 2: Vérification du code OTP
  Widget _buildOTPStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.verified_user,
              size: 80,
              color: primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Vérification',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Entrez le code à 6 chiffres envoyé au ${_phoneController.text}',
              style: const TextStyle(
                fontSize: 15,
                color: darkGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // Champs OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextFormField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Renvoyer le code
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _resendOTP,
                child: const Text(
                  'Renvoyer le code',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Vérifier le code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Étape 3: Création du nouveau mot de passe
  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Nouveau mot de passe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Créez un nouveau mot de passe sécurisé (minimum 8 caractères)',
              style: TextStyle(
                fontSize: 15,
                color: darkGray,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // Nouveau mot de passe
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                hintText: 'Minimum 8 caractères',
                prefixIcon: const Icon(Icons.lock, color: primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: darkGray,
                  ),
                  onPressed: () {
                    setState(() => _obscureNewPassword = !_obscureNewPassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                if (value.length < 8) {
                  return 'Le mot de passe doit contenir au moins 8 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Confirmer le mot de passe
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                hintText: 'Retapez votre mot de passe',
                prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: darkGray,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez confirmer votre mot de passe';
                }
                if (value != _newPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Réinitialiser le mot de passe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
