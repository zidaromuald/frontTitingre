import 'package:http/http.dart' as http;
import 'dart:convert';


class AuthService {
  final String baseUrl = 'http://192.168.1.75:8000/api'; // Remplacez par l'URL de votre API

  Future<bool> register(String nom, String prenom, String numero, String email,String dateNaissance,String password, 
  String confirmationPassword, Function(String) showSnackbar) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nom': nom,
        'prenom': prenom,
        'numero': numero,
        'email': email,
        'date_naissance': dateNaissance,
        'password': password,
        'password_confirmation': confirmationPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 200) {
    // Inscription réussie
    showSnackbar('Inscription réussie !');
    return true;
  } else {
    // Gestion des erreurs
    print('Erreur: ${response.statusCode}');

    // Tentez de décoder la réponse
    try {
      final Map<String, dynamic> errorResponse = json.decode(response.body);
      print('Message d\'erreur: ${errorResponse['message']}');
      // Si vous avez d'autres informations dans la réponse, affichez-les
      if (errorResponse.containsKey('errors')) {
        print('Détails des erreurs: ${errorResponse['errors']}');
      }
    } catch (e) {
      // Si la réponse n'est pas du JSON, affichez le corps brut
      print('Réponse non JSON: ${response.body}');
    }
    showSnackbar('Inscription échouée !');
    return false; // Échec de l'inscription
  }  
  }

  Future<Map<String, dynamic>?> login(String identifiant, String password, Function(String) showSnackbar) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'identifiant': identifiant,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // Connexion réussie
      showSnackbar('Connexion réussie !');
      return json.decode(response.body);
    } else {
      // Gestion des erreurs
      showSnackbar('connexion echouer !');
      print(json.decode(response.body));
      return null;
    }
  }
  /*class LoginResult {
    final Map<String, dynamic>? data;
    final String? error;

    LoginResult({this.data, this.error});
  }

  Future<LoginResult> login(String identifiant, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'identifiant': identifiant,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return LoginResult(data: json.decode(response.body));
      } else {
        print('Erreur: ${response.statusCode}');
        final errorResponse = json.decode(response.body);
        return LoginResult(error: errorResponse['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      return LoginResult(error: 'Erreur de réseau: $e');
    }
  }*/
}

