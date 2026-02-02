import 'dart:convert';
import 'dart:typed_data';
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
    if (photo == null) return null;
    // Si l'URL est déjà complète (commence par http), la retourner telle quelle
    if (photo!.startsWith('http')) return photo;
    // Sinon, construire l'URL complète avec l'API base URL
    return 'https://api.titingre.com/storage/$photo';
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
    // Vérifier que l'id est présent et valide
    final id = json['id'];
    if (id == null) {
      print('⚠️ [UserModel] JSON sans id valide: $json');
      throw ArgumentError('UserModel.fromJson: id est requis mais est null');
    }

    // Convertir l'id en int de manière sécurisée
    final int parsedId;
    if (id is int) {
      parsedId = id;
    } else if (id is String) {
      parsedId = int.tryParse(id) ?? 0;
    } else {
      parsedId = 0;
    }

    return UserModel(
      id: parsedId,
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      email: json['email']?.toString(),
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
    print('🔑 [UserAuthService] Tentative de connexion...');
    print('👤 [UserAuthService] Identifiant: $identifiant');

    final data = {'identifiant': identifiant, 'password': password};

    print('📤 [UserAuthService] Envoi POST /auth/login...');
    final response = await ApiService.post('/auth/login', data);

    print('📥 [UserAuthService] Status code: ${response.statusCode}');
    print('📥 [UserAuthService] Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      print('✅ [UserAuthService] Réponse parsée avec succès');
      print('📦 [UserAuthService] jsonResponse keys: ${jsonResponse.keys.toList()}');
      print('📦 [UserAuthService] jsonResponse: $jsonResponse');

      // Vérifier la structure de la réponse
      if (!jsonResponse.containsKey('data')) {
        print('⚠️ [UserAuthService] ATTENTION: Pas de clé "data" dans la réponse!');
        print('📋 [UserAuthService] Clés disponibles: ${jsonResponse.keys.toList()}');
        // Essayer de traiter directement la réponse
        await AuthBaseService.handleLoginResponse(jsonResponse, 'user');
        return UserModel.fromJson(jsonResponse['user']);
      }

      print('📦 [UserAuthService] jsonResponse["data"]: ${jsonResponse['data']}');

      // Sauvegarder le token et les infos
      print('💾 [UserAuthService] Appel de handleLoginResponse...');
      await AuthBaseService.handleLoginResponse(jsonResponse['data'], 'user');

      // Retourner l'utilisateur
      print('👤 [UserAuthService] Création du UserModel...');
      final user = UserModel.fromJson(jsonResponse['data']['user']);
      print('🎉 [UserAuthService] Connexion réussie pour: ${user.fullName}');
      return user;
    } else {
      print('❌ [UserAuthService] Erreur de connexion - Status: ${response.statusCode}');
      print('❌ [UserAuthService] Body: ${response.body}');
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
    print('🔍 [UserAuthService] getMyProfile() - Appel GET /users/me...');

    // Vérifier d'abord si on est bien connecté en tant que User
    final userType = await AuthBaseService.getUserType();
    print('🔍 [UserAuthService] Type utilisateur stocké: $userType');

    if (userType != 'user') {
      print('⚠️ [UserAuthService] ATTENTION: userType != "user" (=$userType)');
      throw Exception('Non connecté en tant que User (type=$userType)');
    }

    final response = await ApiService.get('/users/me');
    print('📥 [UserAuthService] Response status: ${response.statusCode}');
    print('📥 [UserAuthService] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final user = UserModel.fromJson(jsonResponse['data']);
      print('✅ [UserAuthService] User récupéré: id=${user.id}, nom=${user.nom}, prenom=${user.prenom}');
      return user;
    } else {
      print('❌ [UserAuthService] Erreur: ${response.statusCode} - ${response.body}');
      throw Exception('Profil non trouvé (status=${response.statusCode})');
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

  /// Upload photo de profil (version fichier - NON compatible web)
  /// POST /users/me/photo
  /// @deprecated Utiliser uploadProfilePhotoBytes() pour le web
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

  /// Upload photo de profil via bytes (compatible WEB et mobile)
  /// POST /users/me/photo
  static Future<Map<String, dynamic>> uploadProfilePhotoBytes(
    Uint8List bytes,
    String filename,
  ) async {
    final response = await ApiService.uploadBytesToEndpoint(
      bytes,
      filename,
      '/users/me/photo',
      fieldName: 'file',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      // Le backend peut retourner 'data' ou directement les champs
      final data = jsonResponse['data'] ?? jsonResponse;
      return Map<String, dynamic>.from(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de l\'upload de la photo',
      );
    }
  }

  /// Rechercher des utilisateurs
  /// Utilise l'endpoint autocomplete qui fonctionne avec le paramètre 'term'
  static Future<List<UserModel>> searchUsers({
    required String query,
    int? limit,
    int? offset,
  }) async {
    // Encoder le terme de recherche pour éviter les problèmes avec espaces et caractères spéciaux
    final encodedQuery = Uri.encodeQueryComponent(query);
    print('🔍 [UserAuth] searchUsers: "$query" (encoded: "$encodedQuery")');

    // Utiliser autocomplete qui fonctionne avec 'term' au lieu de /users/search?q=
    // Le backend n'accepte pas les params q et limit sur /users/search
    print('🔍 [UserAuth] GET /users/autocomplete?term=$encodedQuery');
    final response = await ApiService.get('/users/autocomplete?term=$encodedQuery');

    print('🔍 [UserAuth] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> usersData = jsonResponse['data'] ?? [];
      print('🔍 [UserAuth] searchUsers: ${usersData.length} résultats');

      // Appliquer la limite côté client si spécifiée
      var results = usersData.map((json) => UserModel.fromJson(json)).toList();
      if (limit != null && results.length > limit) {
        results = results.take(limit).toList();
      }
      if (offset != null && offset > 0 && results.length > offset) {
        results = results.skip(offset).toList();
      }

      return results;
    } else {
      print('❌ [UserAuth] searchUsers erreur: ${response.body}');
      throw Exception('Erreur de recherche: ${response.statusCode}');
    }
  }

  /// Autocomplétion pour la recherche d'utilisateurs
  static Future<List<UserModel>> autocomplete(String term) async {
    // Encoder le terme pour éviter les problèmes avec espaces et caractères spéciaux
    final encodedTerm = Uri.encodeQueryComponent(term);
    print('🔍 [UserAuth] Autocomplete users pour: "$term" (encoded: "$encodedTerm")');
    final response = await ApiService.get('/users/autocomplete?term=$encodedTerm');

    print('🔍 [UserAuth] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> usersData = jsonResponse['data'] ?? [];
      print('🔍 [UserAuth] Users data count: ${usersData.length}');
      return usersData.map((json) => UserModel.fromJson(json)).toList();
    } else {
      print('❌ [UserAuth] Erreur: ${response.body}');
      throw Exception('Erreur d\'autocomplétion: ${response.statusCode}');
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
