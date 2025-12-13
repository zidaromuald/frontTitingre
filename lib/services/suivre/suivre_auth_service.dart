import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Type d'entité suivie (User ou Societe)
enum EntityType {
  user('User'),
  societe('Societe');

  final String value;
  const EntityType(this.value);

  factory EntityType.fromString(String value) {
    return EntityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EntityType.user,
    );
  }
}

/// Statut d'abonnement
enum AbonnementStatut {
  actif('actif'),
  inactif('inactif'),
  suspendu('suspendu');

  final String value;
  const AbonnementStatut(this.value);

  factory AbonnementStatut.fromString(String value) {
    return AbonnementStatut.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AbonnementStatut.inactif,
    );
  }
}

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle Suivre (relation de suivi)
class SuivreModel {
  final int userId;
  final String userType; // 'User' ou 'Societe'
  final int followedId;
  final String followedType; // 'User' ou 'Societe'
  final bool notificationsActives;
  final int frequenceInteraction;
  final int scoreEngagement;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SuivreModel({
    required this.userId,
    required this.userType,
    required this.followedId,
    required this.followedType,
    this.notificationsActives = true,
    this.frequenceInteraction = 0,
    this.scoreEngagement = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SuivreModel.fromJson(Map<String, dynamic> json) {
    return SuivreModel(
      userId: json['user_id'],
      userType: json['user_type'],
      followedId: json['followed_id'],
      followedType: json['followed_type'],
      notificationsActives: json['notifications_actives'] ?? true,
      frequenceInteraction: json['frequence_interaction'] ?? 0,
      scoreEngagement: json['score_engagement'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_type': userType,
      'followed_id': followedId,
      'followed_type': followedType,
      'notifications_actives': notificationsActives,
      'frequence_interaction': frequenceInteraction,
      'score_engagement': scoreEngagement,
    };
  }
}

/// Modèle Abonnement (upgrade d'un suivi)
class AbonnementModel {
  final int id;
  final int userId;
  final int societeId;
  final AbonnementStatut statut;
  final String? planCollaboration;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final DateTime? createdAt;

  AbonnementModel({
    required this.id,
    required this.userId,
    required this.societeId,
    required this.statut,
    this.planCollaboration,
    this.dateDebut,
    this.dateFin,
    this.createdAt,
  });

  factory AbonnementModel.fromJson(Map<String, dynamic> json) {
    return AbonnementModel(
      id: json['id'],
      userId: json['user_id'],
      societeId: json['societe_id'],
      statut: AbonnementStatut.fromString(json['statut'] ?? 'inactif'),
      planCollaboration: json['plan_collaboration'],
      dateDebut: json['date_debut'] != null
          ? DateTime.parse(json['date_debut'])
          : null,
      dateFin: json['date_fin'] != null
          ? DateTime.parse(json['date_fin'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}

/// Modèle PagePartenariat
class PagePartenariatModel {
  final int id;
  final String titre;
  final String visibilite;

  PagePartenariatModel({
    required this.id,
    required this.titre,
    required this.visibilite,
  });

  factory PagePartenariatModel.fromJson(Map<String, dynamic> json) {
    return PagePartenariatModel(
      id: json['id'],
      titre: json['titre'],
      visibilite: json['visibilite'],
    );
  }
}

// ============================================================================
// SERVICE SUIVRE
// ============================================================================

/// Service de gestion des suivis (User ↔ User, User ↔ Societe, Societe ↔ User, Societe ↔ Societe)
class SuivreAuthService {
  /// Suivre une entité (User ou Societe)
  /// POST /suivis
  static Future<SuivreModel> suivre({
    required int followedId,
    required EntityType followedType,
  }) async {
    final data = {
      'followed_id': followedId,
      'followed_type': followedType.value,
    };

    final response = await ApiService.post('/suivis', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return SuivreModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors du suivi');
    }
  }

  /// Ne plus suivre une entité
  /// DELETE /suivis/:type/:id
  static Future<void> unfollow({
    required int followedId,
    required EntityType followedType,
  }) async {
    final response = await ApiService.delete(
      '/suivis/${followedType.value}/$followedId',
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'arrêt du suivi');
    }
  }

  /// Mettre à jour les préférences de suivi
  /// PUT /suivis/:type/:id
  static Future<SuivreModel> updateSuivi({
    required int followedId,
    required EntityType followedType,
    bool? notificationsActives,
  }) async {
    final data = {
      if (notificationsActives != null)
        'notifications_actives': notificationsActives,
    };

    final response = await ApiService.put(
      '/suivis/${followedType.value}/$followedId',
      data,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return SuivreModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour');
    }
  }

  /// Vérifier si je suis une entité
  /// GET /suivis/:type/:id/check
  static Future<bool> checkSuivi({
    required int followedId,
    required EntityType followedType,
  }) async {
    final response = await ApiService.get(
      '/suivis/${followedType.value}/$followedId/check',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']['is_suivant'] ?? false;
    } else {
      throw Exception('Erreur de vérification');
    }
  }

  /// Récupérer mes suivis (les entités que je suis)
  /// GET /suivis/my-following?type=User|Societe
  static Future<List<SuivreModel>> getMyFollowing({EntityType? type}) async {
    final queryParams = type != null ? '?type=${type.value}' : '';
    final response = await ApiService.get('/suivis/my-following$queryParams');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> suivresData = jsonResponse['data'];
      return suivresData.map((json) => SuivreModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des suivis');
    }
  }

  /// Récupérer les followers d'une entité
  /// GET /suivis/:type/:id/followers
  static Future<List<Map<String, dynamic>>> getFollowers({
    required int entityId,
    required EntityType entityType,
  }) async {
    final response = await ApiService.get(
      '/suivis/${entityType.value}/$entityId/followers',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception('Erreur de récupération des followers');
    }
  }

  /// Upgrade vers abonnement (UNIQUEMENT pour User → Societe)
  /// POST /suivis/upgrade-to-abonnement
  static Future<Map<String, dynamic>> upgradeToAbonnement({
    required int societeId,
    String? planCollaboration,
  }) async {
    final data = {
      'societe_id': societeId,
      if (planCollaboration != null) 'plan_collaboration': planCollaboration,
    };

    final response = await ApiService.post(
      '/suivis/upgrade-to-abonnement',
      data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return {
        'abonnement': AbonnementModel.fromJson(
          jsonResponse['data']['abonnement'],
        ),
        'page_partenariat': PagePartenariatModel.fromJson(
          jsonResponse['data']['page_partenariat'],
        ),
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'upgrade');
    }
  }

  /// Statistiques d'une société
  /// GET /suivis/societe/:id/stats
  /*static Future<Map<String, dynamic>> getSocieteStats(int societeId) async {
    final response = await ApiService.get('/suivis/societe/$societeId/stats');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }*/
}
