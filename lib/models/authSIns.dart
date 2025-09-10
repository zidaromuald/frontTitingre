import 'package:http/http.dart' as http;
import 'dart:convert';


class AuthsService {
  final String baseUrl = 'http://192.168.1.75:8000/api'; // Remplacez par l'URL de votre API
  Future<bool> register(String societe, String numero, String email,String centreInteret, String domaine
  , String typeProduit, String password,  String confirmationPassword, Function(String) showSnackbar) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/societe'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'societe': societe,
        'numero': numero,
        'email': email,
        'centre_interet': centreInteret,
        'domaine': domaine,
        'type_produit': typeProduit,
        'password': password,
        'password_confirmation': confirmationPassword,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 200) {
    // Inscription réussie
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
    return false; // Échec de l'inscription
  }  
  }

  Future<Map<String, dynamic>?> login(String identifiant, String password, Function(String) showSnackbar) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/societe'),
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
  }