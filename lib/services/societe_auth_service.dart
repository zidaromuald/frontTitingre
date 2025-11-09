import 'dart:convert';
import 'api_service.dart';
import 'auth_base_service.dart';

/// Modèle Societe
class SocieteModel {
  final int id;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;
  final String? secteurActivite;
  final String? description;
  final String? logoUrl;

  SocieteModel({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
    this.secteurActivite,
    this.description,
    this.logoUrl,
  });

  factory SocieteModel.fromJson(Map<String, dynamic> json) {
    return SocieteModel(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      secteurActivite: json['secteur_activite'],
      description: json['description'],
      logoUrl: json['logo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'secteur_activite': secteurActivite,
      'description': description,
      'logo_url': logoUrl,
    };
  }
}

/// Service d'authentification pour les SOCIETES
class SocieteAuthService {
  /// Inscription d'une société
  static Future<SocieteModel> register({
    required String nom,
    required String email,
    required String password,
    String? telephone,
    String? adresse,
    String? secteurActivite,
    String? description,
  }) async {
    final data = {
      'nom': nom,
      'email': email,
      'password': password,
      if (telephone != null) 'telephone': telephone,
      if (adresse != null) 'adresse': adresse,
      if (secteurActivite != null) 'secteur_activite': secteurActivite,
      if (description != null) 'description': description,
    };

    final response = await ApiService.post('/auth/societe/register', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      // Sauvegarder le token et les infos
      await AuthBaseService.handleLoginResponse(
        jsonResponse['data'],
        'societe',
      );

      // Retourner la société
      return SocieteModel.fromJson(jsonResponse['data']['societe']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'inscription');
    }
  }

  /// Connexion d'une société
  static Future<SocieteModel> login({
    required String identifiant, // email ou nom de société
    required String password,
  }) async {
    final data = {
      'identifiant': identifiant,
      'password': password,
    };

    final response = await ApiService.post('/auth/societe/login', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      // Sauvegarder le token et les infos
      await AuthBaseService.handleLoginResponse(
        jsonResponse['data'],
        'societe',
      );

      // Retourner la société
      return SocieteModel.fromJson(jsonResponse['data']['societe']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de connexion');
    }
  }

  /// Récupérer les informations de la société connectée
  static Future<SocieteModel> getMe() async {
    final response = await ApiService.get('/auth/societe/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SocieteModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Société non authentifiée');
    }
  }

  /// Déconnexion
  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/societe/logout', {});
    } catch (e) {
      // Même si l'appel échoue, on déconnecte localement
    } finally {
      await AuthBaseService.logout();
    }
  }

  /// Déconnexion de tous les appareils
  static Future<void> logoutAll() async {
    try {
      await ApiService.post('/auth/societe/logout-all', {});
    } catch (e) {
      // Même si l'appel échoue, on déconnecte localement
    } finally {
      await AuthBaseService.logout();
    }
  }

  /// Récupérer la société depuis le cache local
  static Future<SocieteModel?> getCachedSociete() async {
    final societeData = await AuthBaseService.getUserData();
    if (societeData != null) {
      return SocieteModel.fromJson(societeData);
    }
    return null;
  }

  /// Rechercher des sociétés
  static Future<List<SocieteModel>> searchSocietes({
    String? query,
    String? secteur,
    String? produit,
    int? limit,
    int? offset,
  }) async {
    final params = <String>[];
    if (query != null) params.add('q=$query');
    if (secteur != null) params.add('secteur=$secteur');
    if (produit != null) params.add('produit=$produit');
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get('/societes/search$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> societesData = jsonResponse['data'];
      return societesData.map((json) => SocieteModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche');
    }
  }

  /// Recherche rapide par nom
  static Future<List<SocieteModel>> searchByName(String name) async {
    final response = await ApiService.get('/societes/search-by-name?q=$name');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> societesData = jsonResponse['data'];
      return societesData.map((json) => SocieteModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche');
    }
  }

  /// Recherche avancée
  static Future<List<SocieteModel>> advancedSearch({
    String? nom,
    String? secteur,
    List<String>? produits,
    List<String>? centresInteret,
    int? limit,
    int? offset,
  }) async {
    final params = <String>[];
    if (nom != null) params.add('nom=$nom');
    if (secteur != null) params.add('secteur=$secteur');
    if (produits != null && produits.isNotEmpty) {
      params.add('produits=${produits.join(',')}');
    }
    if (centresInteret != null && centresInteret.isNotEmpty) {
      params.add('centres_interet=${centresInteret.join(',')}');
    }
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get('/societes/advanced-search$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> societesData = jsonResponse['data'];
      return societesData.map((json) => SocieteModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche avancée');
    }
  }

  /// Autocomplétion pour la recherche de sociétés
  static Future<List<SocieteModel>> autocomplete(String term) async {
    final response = await ApiService.get('/societes/autocomplete?term=$term');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> societesData = jsonResponse['data'];
      return societesData.map((json) => SocieteModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur d\'autocomplétion');
    }
  }

  /// Récupérer les filtres disponibles
  static Future<Map<String, dynamic>> getFilters() async {
    final response = await ApiService.get('/societes/filters');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de récupération des filtres');
    }
  }

  /// Vérifier si une société est connectée
  static Future<bool> isLoggedIn() async {
    final userType = await AuthBaseService.getUserType();
    return userType == 'societe' && await AuthBaseService.isAuthenticated();
  }
}
