import 'dart:convert';
import 'api_service.dart';
import 'auth_base_service.dart';

/// Modèle User
class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? photoUrl;
  final String? bio;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.photoUrl,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      telephone: json['telephone'],
      photoUrl: json['photo_url'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'photo_url': photoUrl,
      'bio': bio,
    };
  }

  String get fullName => '$prenom $nom';
}

/// Service d'authentification pour les USERS
class UserAuthService {
  /// Inscription d'un utilisateur
  static Future<UserModel> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    String? telephone,
  }) async {
    final data = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
      if (telephone != null) 'telephone': telephone,
    };

    final response = await ApiService.post('/auth/register', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      // Sauvegarder le token et les infos
      await AuthBaseService.handleLoginResponse(
        jsonResponse['data'],
        'user',
      );

      // Retourner l'utilisateur
      return UserModel.fromJson(jsonResponse['data']['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'inscription');
    }
  }

  /// Connexion d'un utilisateur
  static Future<UserModel> login({
    required String identifiant, // email ou téléphone
    required String password,
  }) async {
    final data = {
      'identifiant': identifiant,
      'password': password,
    };

    final response = await ApiService.post('/auth/login', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      // Sauvegarder le token et les infos
      await AuthBaseService.handleLoginResponse(
        jsonResponse['data'],
        'user',
      );

      // Retourner l'utilisateur
      return UserModel.fromJson(jsonResponse['data']['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de connexion');
    }
  }

  /// Récupérer les informations de l'utilisateur connecté
  static Future<UserModel> getMe() async {
    final response = await ApiService.get('/auth/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return UserModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Utilisateur non authentifié');
    }
  }

  /// Déconnexion
  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout', {});
    } catch (e) {
      // Même si l'appel échoue, on déconnecte localement
    } finally {
      await AuthBaseService.logout();
    }
  }

  /// Déconnexion de tous les appareils
  static Future<void> logoutAll() async {
    try {
      await ApiService.post('/auth/logout-all', {});
    } catch (e) {
      // Même si l'appel échoue, on déconnecte localement
    } finally {
      await AuthBaseService.logout();
    }
  }

  /// Récupérer l'utilisateur depuis le cache local
  static Future<UserModel?> getCachedUser() async {
    final userData = await AuthBaseService.getUserData();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  /// Rechercher des utilisateurs
  static Future<List<UserModel>> searchUsers({
    required String query,
    int? limit,
    int? offset,
  }) async {
    final params = <String>[];
    params.add('q=$query');
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get('/users/search$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> usersData = jsonResponse['data'];
      return usersData.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche');
    }
  }

  /// Autocomplétion pour la recherche d'utilisateurs
  static Future<List<UserModel>> autocomplete(String term) async {
    final response = await ApiService.get('/users/autocomplete?term=$term');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> usersData = jsonResponse['data'];
      return usersData.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur d\'autocomplétion');
    }
  }

  /// Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final userType = await AuthBaseService.getUserType();
    return userType == 'user' && await AuthBaseService.isAuthenticated();
  }
}
