import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestauth_clean/is/AccueilPage.dart';
import 'package:gestauth_clean/models/authSIns.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class InscriptionSPage extends StatefulWidget {
  const InscriptionSPage({super.key});

  @override
  State<InscriptionSPage> createState() => _InscriptionSPageState();
}

class _InscriptionSPageState extends State<InscriptionSPage> {
  final TextEditingController _societeController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _typeProduitController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedCentreInteret;
  String? _selectedDomaine;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _centresInteret = ['Agricole', 'Elevage'];
  final List<String> _domaines = [
    'Societe_Negoce',
    'Societe_Transformateur',
    'Societe_Exportatrice',
  ];

  @override
  void dispose() {
    _societeController.dispose();
    _numeroController.dispose();
    _emailController.dispose();
    _typeProduitController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

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

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCentreInteret == null) {
      _showMessage('Veuillez sélectionner un centre d\'intérêt', isError: true);
      return;
    }

    if (_selectedDomaine == null) {
      _showMessage('Veuillez sélectionner un domaine', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final societe = _societeController.text.trim();
    final numero = _numeroController.text.trim();
    final email = _emailController.text.trim();
    final typeProduit = _typeProduitController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showMessage('Les mots de passe ne correspondent pas', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final authService = AuthsService();
      final success = await authService.register(
        societe,
        numero,
        email,
        _selectedCentreInteret!,
        _selectedDomaine!,
        typeProduit,
        password,
        confirmPassword,
        _showMessage,
      );

      if (success && mounted) {
        _showMessage('Inscription réussie !');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AccueilPage()),
        );
      }
    } catch (e) {
      _showMessage(
        'Une erreur est survenue. Veuillez réessayer.',
        isError: true,
      );
      debugPrint('Erreur inscription société: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Widget pour le champ Nom de société
  Widget _buildSocieteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nom de la société',
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
            controller: _societeController,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.black87),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom de la société est requis';
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(Icons.business, color: Color(0xff5ac18e)),
              hintText: 'Nom de votre société',
              hintStyle: TextStyle(color: Colors.black38),
              errorStyle: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour le champ Téléphone
  Widget _buildTelephoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Téléphone',
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
          child: IntlPhoneField(
            controller: _numeroController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              hintText: 'Numéro de téléphone',
              hintStyle: TextStyle(color: Colors.black38),
              prefixIcon: Icon(Icons.phone, color: Color(0xff5ac18e)),
              errorStyle: TextStyle(color: Colors.red, fontSize: 12),
            ),
            initialCountryCode: 'BF',
            validator: (phone) {
              if (phone == null || phone.completeNumber.isEmpty) {
                return 'Le numéro de téléphone est requis';
              }
              return null;
            },
            onChanged: (phone) {
              // ✅ SOLUTION: Stocker le numéro complet dans le contrôleur
              setState(() {
                _numeroController.text = phone.completeNumber;
              });
            },
          ),
        ),
      ],
    );
  }

  // Widget pour le champ Email
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
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
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.black87),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'email est requis';
              }
              if (!_isValidEmail(value.trim())) {
                return 'Format d\'email invalide';
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(Icons.email, color: Color(0xff5ac18e)),
              hintText: 'Email de la société',
              hintStyle: TextStyle(color: Colors.black38),
              errorStyle: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour le champ Centre d'intérêt
  Widget _buildCentreInteretField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Centre d\'intérêt',
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
          child: DropdownButtonFormField<String>(
            value: _selectedCentreInteret,
            onChanged: (String? value) {
              setState(() {
                _selectedCentreInteret = value;
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(Icons.category, color: Color(0xff5ac18e)),
              hintText: 'Sélectionnez votre centre d\'intérêt',
              hintStyle: TextStyle(color: Colors.black38),
              errorStyle: TextStyle(color: Colors.red, fontSize: 12),
            ),
            items: _centresInteret.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Widget pour le champ Domaine
  Widget _buildDomaineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Domaine d\'activité',
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
          child: DropdownButtonFormField<String>(
            value: _selectedDomaine,
            onChanged: (String? value) {
              setState(() {
                _selectedDomaine = value;
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(Icons.domain, color: Color(0xff5ac18e)),
              hintText: 'Sélectionnez votre domaine d\'activité',
              hintStyle: TextStyle(color: Colors.black38),
              errorStyle: TextStyle(color: Colors.red, fontSize: 12),
            ),
            items: _domaines.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item.replaceAll('_', ' ')),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Widget pour le champ Type de produit
  Widget _buildTypeProduitField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de produit',
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
            controller: _typeProduitController,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.black87),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le type de produit est requis';
              }
              return null;
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(Icons.inventory, color: Color(0xff5ac18e)),
              hintText: 'Type de produit commercialisé',
              hintStyle: TextStyle(color: Colors.black38),
              errorStyle: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour le champ mot de passe
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(Icons.lock, color: Color(0xff5ac18e)),
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

  // Widget pour le champ confirmation mot de passe
  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmer le mot de passe',
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
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(color: Colors.black87),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez confirmer le mot de passe';
              }
              if (value != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xff5ac18e),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: const Color(0xff5ac18e),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              hintText: 'Confirmez votre mot de passe',
              hintStyle: const TextStyle(color: Colors.black38),
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Bouton d'inscription
  Widget _buildRegistrationButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegistration,
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
                'S\'INSCRIRE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      'Inscription Société',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),
                    _buildSocieteField(),
                    const SizedBox(height: 20),
                    _buildTelephoneField(),
                    const SizedBox(height: 20),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildCentreInteretField(),
                    const SizedBox(height: 20),
                    _buildDomaineField(),
                    const SizedBox(height: 20),
                    _buildTypeProduitField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 20),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 30),
                    _buildRegistrationButton(),
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

/*class InscriptionSPage extends StatefulWidget {
  const InscriptionSPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _InscriptionPageState createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionSPage> {
  //final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _societeController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? selectedcentreInteret;
  String? selecteddomaine;
  final TextEditingController _typeProduitController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmationPasswordController =
      TextEditingController();

  void despose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _societeController.dispose();
    _typeProduitController.dispose();
    _numeroController.dispose();
    selectedcentreInteret;
    selecteddomaine;
    _confirmationPasswordController.dispose();
  }

  bool isLoading = false;
  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2), // Durée d'affichage du SnackBar
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget buildNom() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Nom_Sociéte',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]),
              height: 60,
              child: TextField(
                controller: _societeController,
                keyboardType: TextInputType.name,
                style: const TextStyle(
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 14),
                    prefixIcon: Icon(Icons.home_work, color: Color(0xff5ac18e)),
                    hintText: 'Societe',
                    hintStyle: TextStyle(color: Colors.black38)),
              ))
        ],
      );
    }

    Widget buildTelephone() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Numero',
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
            child: IntlPhoneField(
              controller: _numeroController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                hintText: 'Telephone',
                hintStyle: TextStyle(
                  color: Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.contact_phone,
                  color: Color(0xff5ac18e),
                ),
              ),
              initialCountryCode: 'FR', // Définir le pays par défaut
            ),
          ),
        ],
      );
    }

    Widget buildEmail() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Email',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]),
              height: 60,
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: Colors.black87,
                ),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 14),
                    prefixIcon: Icon(Icons.email, color: Color(0xff5ac18e)),
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.black38)),
              ))
        ],
      );
    }

    Widget buildCentreInteret() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Centre_intérêt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
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
            height: 60,
            child: FormBuilderDropdown(
              name: 'my_combobox',
              decoration: const InputDecoration(
                labelText: 'Choisissez votre option',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Agricole', child: Text('Agricole')),
                DropdownMenuItem(value: 'Elevage', child: Text('Elevage')),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  selectedcentreInteret =
                      newValue; // Mise à jour de la variable d'état
                });
              },
            ),
          ),
        ],
      );
    }

    Widget builddomaine() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Domaine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
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
            height: 60,
            child: FormBuilderDropdown(
              name: 'my_combobox', // Nom du champ
              decoration: const InputDecoration(
                labelText: 'Choisissez votre option',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Societe_Negoce', child: Text('Societe_Negoce')),
                DropdownMenuItem(
                    value: 'Societe_Transformateur',
                    child: Text('Societe_Transformateur')),
                DropdownMenuItem(
                    value: 'Societe_Exportatrice',
                    child: Text('Societe_Exportatrice')),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  selecteddomaine =
                      newValue; // Mise à jour de la variable d'état
                });
              },
            ),
          ),
        ],
      );
    }

    Widget buildProduit() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Type_Produit',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]),
            height: 60,
            child: TextField(
              controller: _typeProduitController,
              style: const TextStyle(
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 14),
                  prefixIcon: Icon(Icons.production_quantity_limits_rounded,
                      color: Color(0xff5ac18e)),
                  hintText: 'Produit',
                  hintStyle: TextStyle(color: Colors.black38)),
            ),
          )
        ],
      );
    }

    Widget buildPassword() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Password',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]),
            height: 60,
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 14),
                  prefixIcon:
                      Icon(Icons.lock, color: Color.fromRGBO(90, 193, 142, 1)),
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.black38)),
            ),
          )
        ],
      );
    }

    // ignore: non_constant_identifier_names
    Widget buildConfirmation_Password() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Confirme_Password',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]),
            height: 60,
            child: TextField(
              controller: _confirmationPasswordController,
              obscureText: true,
              style: const TextStyle(
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 14),
                  prefixIcon:
                      Icon(Icons.lock, color: Color.fromRGBO(90, 193, 142, 1)),
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.black38)),
            ),
          )
        ],
      );
    }

/* Widget buildConfirmer() {
  return Container(
    alignment: Alignment.center,
    child: ElevatedButton(
      onPressed: () async {
        setState(() {
          isLoading = true; // Indiquer que le chargement a commencé
        });
        // Récupérer les données des contrôleurs
        final nom = _societeController.text;
        final numero = _numeroController.text;
        final email = _emailController.text;
        final typeProduit = _typeProduitController.text;
        final password = _passwordController.text.trim();
        final confirmationPassword = _confirmationPasswordController.text.trim();
        
        final authService = AuthsService();
        try {
          final success = await authService.register(nom, numero, email, password, typeProduit,
          confirmationPassword, showSnackbar, );

          if (success) {
            // Inscription réussie
            print('Utilisateur inscrit avec succès');
            // Optionnel : Naviguer vers une autre page ou afficher un message
          } else {
            // Gérer les erreurs
            print('Inscription echoué');
          }
        } catch (e) {
          // Gérer les exceptions
          print('Exception: $e');
        } finally {
          setState(() {
            isLoading = false; // Indiquer que le chargement est terminé
          });
        }
      },
      child: const Text(
        "CONFIRMER",
        style: TextStyle(
          color: Color.fromRGBO(90, 193, 142, 1),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
 }*/
    Widget buildConfirmer() {
      return Container(
        alignment: Alignment.center,
        child: ElevatedButton(
          onPressed: () async {
            setState(() {
              isLoading = true; // Indiquer que le chargement a commencé
            });

            // Récupérer les données des contrôleurs
            final societe = _societeController.text;
            final numero = _numeroController.text;
            final email = _emailController.text;
            final centreInteret = selectedcentreInteret ??
                ''; // Assurez-vous que cette variable est définie
            final domaine = selecteddomaine ?? '';
            final typeProduit = _typeProduitController.text;
            final password = _passwordController.text.trim();
            final confirmationPassword =
                _confirmationPasswordController.text.trim();

            if (selectedcentreInteret == null ||
                selecteddomaine == null ||
                societe.isEmpty ||
                numero.isEmpty ||
                email.isEmpty ||
                typeProduit.isEmpty ||
                password.isEmpty ||
                confirmationPassword.isEmpty) {
              showSnackbar('Veuillez remplir tous les champs requis.');
              setState(() {
                isLoading = false; // Réinitialiser l'état de chargement
              });
              return; // Sortir de la méthode
            }

            if (password != confirmationPassword) {
              showSnackbar('Les mots de passe ne correspondent pas.');
              setState(() {
                isLoading = false; // Réinitialiser l'état de chargement
              });
              return; // Sortir de la méthode
            }

            final authService =
                AuthsService(); // Vérifiez que AuthsService est bien importé
            try {
              final success = await authService.register(
                societe,
                numero,
                email,
                centreInteret,
                domaine,
                typeProduit,
                password,
                confirmationPassword,
                showSnackbar,
              );

              if (success) {
                showSnackbar('Société inscrite avec succès');
                // Optionnel : Naviguer vers une autre page ou afficher un message
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AccueilPage()),
                );
              } else {
                showSnackbar('Inscription échouée');
              }
            } catch (e) {
              showSnackbar('Une erreur est survenue : $e');
            } finally {
              setState(() {
                isLoading = false; // Indiquer que le chargement est terminé
              });
            }
          },
          child: const Text("CONFIRMER",
              style: TextStyle(
                  color: Color.fromRGBO(90, 193, 142, 1),
                  fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          child: Stack(
            children: <Widget>[
              Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          // ignore: unnecessary_const
                          colors: const [
                        Color(0x665ac18e),
                        Color(0x995ac18e),
                        Color(0xcc5ac18e),
                        Color(0xff5ac18e),
                      ])),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 60,
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text('Inscriver-vous',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(
                            height: 30,
                          ),
                          buildNom(),
                          const SizedBox(
                            height: 15,
                          ),
                          buildTelephone(),
                          const SizedBox(
                            height: 15,
                          ),
                          buildEmail(),
                          const SizedBox(
                            height: 15,
                          ),
                          buildCentreInteret(),
                          const SizedBox(
                            height: 15,
                          ),
                          builddomaine(),
                          const SizedBox(
                            height: 15,
                          ),
                          buildProduit(),
                          const SizedBox(
                            height: 15,
                          ),
                          buildPassword(),
                          const SizedBox(
                            height: 15,
                          ),
                          buildConfirmation_Password(),
                          const SizedBox(
                            height: 15,
                          ),
                          buildConfirmer(),
                        ]),
                  )),
            ],
          ),
        ),
      ),
    ); //
  }
}*/
