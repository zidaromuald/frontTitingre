import 'dart:convert';
import '../api_service.dart';
import 'auth_base_service.dart';

/// Modèle SocieteProfil (données détaillées du profil société)
class SocieteProfilModel {
  final int id;
  final int societeId;
  final String? logo;
  final String? description;
  final List<String>? produits;
  final List<String>? services;
  final List<String>? centresInteret;
  final String? siteWeb;
  final int? nombreEmployes;
  final int? anneeCreation;
  final String? chiffreAffaires;
  final String? certifications;

  SocieteProfilModel({
    required this.id,
    required this.societeId,
    this.logo,
    this.description,
    this.produits,
    this.services,
    this.centresInteret,
    this.siteWeb,
    this.nombreEmployes,
    this.anneeCreation,
    this.chiffreAffaires,
    this.certifications,
  });

  factory SocieteProfilModel.fromJson(Map<String, dynamic> json) {
    return SocieteProfilModel(
      id: json['id'],
      societeId: json['societe_id'],
      logo: json['logo'],
      description: json['description'],
      produits: json['produits'] != null
          ? List<String>.from(json['produits'])
          : null,
      services: json['services'] != null
          ? List<String>.from(json['services'])
          : null,
      centresInteret: json['centres_interet'] != null
          ? List<String>.from(json['centres_interet'])
          : null,
      siteWeb: json['site_web'],
      nombreEmployes: json['nombre_employes'],
      anneeCreation: json['annee_creation'],
      chiffreAffaires: json['chiffre_affaires'],
      certifications: json['certifications'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (description != null) 'description': description,
      if (produits != null) 'produits': produits,
      if (services != null) 'services': services,
      if (centresInteret != null) 'centres_interet': centresInteret,
      if (siteWeb != null) 'site_web': siteWeb,
      if (nombreEmployes != null) 'nombre_employes': nombreEmployes,
      if (anneeCreation != null) 'annee_creation': anneeCreation,
      if (chiffreAffaires != null) 'chiffre_affaires': chiffreAffaires,
      if (certifications != null) 'certifications': certifications,
    };
  }

  String? getLogoUrl() {
    return logo != null ? '/storage/$logo' : null;
  }
}

/// Modèle Societe (données de base)
class SocieteModel {
  final int id;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;
  final String? secteurActivite;
  final SocieteProfilModel? profile; // Profil imbriqué

  SocieteModel({
    required this.id,
    required this.nom,
    required this.email,
    this.telephone,
    this.adresse,
    this.secteurActivite,
    this.profile,
  });

  factory SocieteModel.fromJson(Map<String, dynamic> json) {
    return SocieteModel(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      telephone: json['telephone'],
      adresse: json['adresse'],
      secteurActivite: json['secteur_activite'],
      profile: json['profile'] != null
          ? SocieteProfilModel.fromJson(json['profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      if (telephone != null) 'telephone': telephone,
      if (adresse != null) 'adresse': adresse,
      if (secteurActivite != null) 'secteur_activite': secteurActivite,
    };
  }

  // Getters de convenance pour accéder au profil
  String? get logoUrl => profile?.getLogoUrl();
  String? get description => profile?.description;
  List<String>? get produits => profile?.produits;
  List<String>? get services => profile?.services;
}

/// Service d'authentification pour les SOCIETES
class SocieteAuthService {
  /// Inscription d'une société
  /// Correspond au CreateSocieteDto du backend NestJS
  static Future<SocieteModel> register({
    required String nomSociete,
    required String numero,
    required String email,
    required String centreInteret,
    required String secteurActivite,
    required String typeProduit,
    required String password,
    required String passwordConfirmation,
    String? adresse,
  }) async {
    final data = {
      'nom_societe': nomSociete,
      'numero': numero,
      'email': email,
      'centre_interet': centreInteret,
      'secteur_activite': secteurActivite,
      'type_produit': typeProduit,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (adresse != null) 'adresse': adresse,
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
    final data = {'identifiant': identifiant, 'password': password};

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

  /// Récupérer les informations de la société connectée (sans profil)
  static Future<SocieteModel> getMe() async {
    final response = await ApiService.get('/auth/societe/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SocieteModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Société non authentifiée');
    }
  }

  /// Récupérer le profil complet de la société connectée (avec profil)
  static Future<SocieteModel> getMyProfile() async {
    final response = await ApiService.get('/societes/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SocieteModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Profil non trouvé');
    }
  }

  /// Récupérer le profil d'une société par ID
  static Future<SocieteModel> getSocieteProfile(int societeId) async {
    final response = await ApiService.get('/societes/$societeId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SocieteModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Société introuvable');
    }
  }

  /// Mettre à jour mon profil société
  static Future<SocieteProfilModel> updateMyProfile(
    Map<String, dynamic> updates,
  ) async {
    final response = await ApiService.put('/societes/me/profile', updates);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SocieteProfilModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Erreur de mise à jour du profil');
    }
  }

  /// Upload logo de société
  /// POST /societes/me/logo
  static Future<Map<String, dynamic>> uploadLogo(String filePath) async {
    final response = await ApiService.uploadFileToEndpoint(
      filePath,
      '/societes/me/logo',
      fieldName: 'file',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']; // Retourne { logo: '...', url: '...' }
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'upload du logo');
    }
  }

  /// Récupérer les statistiques de ma société
  static Future<Map<String, dynamic>> getMyStats() async {
    final response = await ApiService.get('/societes/me/stats');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }

  /// Récupérer les statistiques d'une société
  static Future<Map<String, dynamic>> getSocieteStats(int societeId) async {
    final response = await ApiService.get('/societes/$societeId/stats');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de récupération des statistiques');
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
    final response = await ApiService.get(
      '/societes/advanced-search$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> societesData = jsonResponse['data'];
      return societesData.map((json) => SocieteModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche avancée');
    }
  }
}
