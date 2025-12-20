import 'dart:convert';
import '../api_service.dart';
import 'auth_base_service.dart';

/// Modèle UserProfil (données détaillées du profil)
class UserProfilModel {
  final int id;
  final int userId;
  final String? photo;
  final String? bio;
  final List<String>? competences;
  final String? experience;
  final String? formation;
  final String? linkedin;
  final String? github;
  final String? portfolio;
  final List<String>? langues;
  final String? disponibilite;
  final double? salaireSouhaite;

  UserProfilModel({
    required this.id,
    required this.userId,
    this.photo,
    this.bio,
    this.competences,
    this.experience,
    this.formation,
    this.linkedin,
    this.github,
    this.portfolio,
    this.langues,
    this.disponibilite,
    this.salaireSouhaite,
  });

  factory UserProfilModel.fromJson(Map<String, dynamic> json) {
    return UserProfilModel(
      id: json['id'],
      userId: json['user_id'],
      photo: json['photo'],
      bio: json['bio'],
      competences: json['competences'] != null
          ? List<String>.from(json['competences'])
          : null,
      experience: json['experience'],
      formation: json['formation'],
      linkedin: json['linkedin'],
      github: json['github'],
      portfolio: json['portfolio'],
      langues: json['langues'] != null
          ? List<String>.from(json['langues'])
          : null,
      disponibilite: json['disponibilite'],
      salaireSouhaite: json['salaire_souhaite']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bio != null) 'bio': bio,
      if (competences != null) 'competences': competences,
      if (experience != null) 'experience': experience,
      if (formation != null) 'formation': formation,
      if (linkedin != null) 'linkedin': linkedin,
      if (github != null) 'github': github,
      if (portfolio != null) 'portfolio': portfolio,
      if (langues != null) 'langues': langues,
      if (disponibilite != null) 'disponibilite': disponibilite,
      if (salaireSouhaite != null) 'salaire_souhaite': salaireSouhaite,
    };
  }

  String? getPhotoUrl() {
    return photo != null ? '/storage/$photo' : null;
  }
}

/// Modèle User (données de base)
class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String numero; // Obligatoire (unique)
  final String? email; // Optionnel
  final UserProfilModel? profile; // Profil imbriqué

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.numero,
    this.email,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      numero: json['numero'],
      email: json['email'],
      profile: json['profile'] != null
          ? UserProfilModel.fromJson(json['profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'numero': numero,
      if (email != null) 'email': email,
    };
  }

  String get fullName => '$prenom $nom';

  // Getters de convenance pour accéder au profil
  String? get photoUrl => profile?.getPhotoUrl();
  String? get bio => profile?.bio;
  List<String>? get competences => profile?.competences;
}

/// Service d'authentification pour les USERS
class UserAuthService {
  /// Inscription d'un utilisateur
  static Future<UserModel> register({
    required String nom,
    required String prenom,
    required String numero, // Obligatoire (format: +225XXXXXXXXXX)
    required String password,
    String? email, // Optionnel
    DateTime? dateNaissance,
    String? activite,
  }) async {
    final data = {
      'nom': nom,
      'prenom': prenom,
      'numero': numero,
      'password': password,
      'password_confirmation': password, // Requis par le backend
      if (email != null) 'email': email,
      if (dateNaissance != null)
        'date_naissance': dateNaissance.toIso8601String().split('T')[0],
      if (activite != null) 'activite': activite,
    };

    final response = await ApiService.post('/auth/register', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      // Sauvegarder le token et les infos
      await AuthBaseService.handleLoginResponse(jsonResponse['data'], 'user');

      // Retourner l'utilisateur
      return UserModel.fromJson(jsonResponse['data']['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'inscription');
    }
  }

  /// Connexion d'un utilisateur
  static Future<UserModel> login({
    required String identifiant, // numero (principal) ou email
    required String password,
  }) async {
    final data = {'identifiant': identifiant, 'password': password};

    final response = await ApiService.post('/auth/login', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      // Sauvegarder le token et les infos
      await AuthBaseService.handleLoginResponse(jsonResponse['data'], 'user');

      // Retourner l'utilisateur
      return UserModel.fromJson(jsonResponse['data']['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de connexion');
    }
  }

  /// Récupérer les informations de l'utilisateur connecté (sans profil)
  static Future<UserModel> getMe() async {
    final response = await ApiService.get('/auth/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return UserModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Utilisateur non authentifié');
    }
  }

  /// Récupérer le profil complet de l'utilisateur connecté (avec profil)
  static Future<UserModel> getMyProfile() async {
    final response = await ApiService.get('/users/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return UserModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Profil non trouvé');
    }
  }

  /// Récupérer le profil d'un utilisateur par ID
  static Future<UserModel> getUserProfile(int userId) async {
    final response = await ApiService.get('/users/$userId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return UserModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Utilisateur introuvable');
    }
  }

  /// Mettre à jour mon profil
  static Future<UserProfilModel> updateMyProfile(
    Map<String, dynamic> updates,
  ) async {
    final response = await ApiService.put('/users/me/profile', updates);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return UserProfilModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Erreur de mise à jour du profil');
    }
  }

  /// Upload photo de profil
  /// POST /users/me/photo
  static Future<Map<String, dynamic>> uploadProfilePhoto(
    String filePath,
  ) async {
    final response = await ApiService.uploadFileToEndpoint(
      filePath,
      '/users/me/photo',
      fieldName: 'file',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']; // Retourne { photo: '...', url: '...' }
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de l\'upload de la photo',
      );
    }
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

  /// Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final userType = await AuthBaseService.getUserType();
    return userType == 'user' && await AuthBaseService.isAuthenticated();
  }

  /// Récupérer l'utilisateur depuis le cache local
  static Future<UserModel?> getCachedUser() async {
    final userData = await AuthBaseService.getUserData();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  /// Récupérer les statistiques de mon profil
  static Future<Map<String, dynamic>> getMyStats() async {
    final response = await ApiService.get('/users/me/stats');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }

  /// Récupérer les statistiques d'un utilisateur
  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    final response = await ApiService.get('/users/$userId/stats');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }
}
