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
  final Map<String, dynamic>? followedUser; // Données de l'utilisateur suivi

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
    this.followedUser,
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
      followedUser: json['followed'] ?? json['followedUser'] ?? json['followed_user'],
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
  /// GET /suivis/my-following?type=User|Societe&include=followed
  /// Si includeDetails=true et le backend ne retourne pas les détails,
  /// on les charge séparément pour chaque utilisateur
  static Future<List<SuivreModel>> getMyFollowing({
    EntityType? type,
    bool includeDetails = false,
  }) async {
    final params = <String>[];
    if (type != null) params.add('type=${type.value}');
    if (includeDetails) params.add('include=followed');
    final queryParams = params.isNotEmpty ? '?${params.join('&')}' : '';

    print('📤 [SuivreAuth] GET /suivis/my-following$queryParams');
    final response = await ApiService.get('/suivis/my-following$queryParams');

    print('📥 [SuivreAuth] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> suivresData = jsonResponse['data'] ?? [];
      print('📥 [SuivreAuth] ${suivresData.length} suivis récupérés');

      // Debug: afficher les détails des suivis
      for (var s in suivresData) {
        final hasFollowed = s['followed'] != null || s['followedUser'] != null || s['followed_user'] != null;
        print('   - Suivi followedId=${s['followed_id']}, hasDetails=$hasFollowed');
      }

      // Convertir en SuivreModel
      List<SuivreModel> suivis = suivresData.map((json) => SuivreModel.fromJson(json)).toList();

      // Si on veut les détails et qu'ils ne sont pas présents, les charger séparément
      if (includeDetails) {
        print('📤 [SuivreAuth] Chargement des détails utilisateurs manquants...');
        suivis = await _enrichSuivisWithUserDetails(suivis, type);
        print('📥 [SuivreAuth] ${suivis.where((s) => s.followedUser != null).length} suivis avec détails');
      }

      return suivis;
    } else {
      print('❌ [SuivreAuth] Erreur: ${response.body}');
      throw Exception('Erreur de récupération des suivis');
    }
  }

  /// Enrichit les suivis avec les détails utilisateur manquants
  static Future<List<SuivreModel>> _enrichSuivisWithUserDetails(
    List<SuivreModel> suivis,
    EntityType? filterType,
  ) async {
    final enrichedSuivis = <SuivreModel>[];

    for (var suivi in suivis) {
      // Si on a déjà les détails, garder tel quel
      if (suivi.followedUser != null) {
        enrichedSuivis.add(suivi);
        continue;
      }

      // Charger les détails de l'utilisateur suivi
      try {
        Map<String, dynamic>? userDetails;

        if (suivi.followedType == 'User') {
          final userResponse = await ApiService.get('/users/${suivi.followedId}');
          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
            userDetails = userData['data'] ?? userData;
            print('   ✅ [SuivreAuth] Détails chargés pour User #${suivi.followedId}');
          }
        } else if (suivi.followedType == 'Societe') {
          final societeResponse = await ApiService.get('/societes/${suivi.followedId}');
          if (societeResponse.statusCode == 200) {
            final societeData = jsonDecode(societeResponse.body);
            userDetails = societeData['data'] ?? societeData;
            print('   ✅ [SuivreAuth] Détails chargés pour Societe #${suivi.followedId}');
          }
        }

        // Créer un nouveau SuivreModel avec les détails
        enrichedSuivis.add(SuivreModel(
          userId: suivi.userId,
          userType: suivi.userType,
          followedId: suivi.followedId,
          followedType: suivi.followedType,
          notificationsActives: suivi.notificationsActives,
          frequenceInteraction: suivi.frequenceInteraction,
          scoreEngagement: suivi.scoreEngagement,
          createdAt: suivi.createdAt,
          updatedAt: suivi.updatedAt,
          followedUser: userDetails,
        ));
      } catch (e) {
        print('   ⚠️ [SuivreAuth] Erreur chargement détails ${suivi.followedType} #${suivi.followedId}: $e');
        enrichedSuivis.add(suivi); // Garder le suivi sans détails
      }
    }

    return enrichedSuivis;
  }

  /// Récupérer les followers d'une entité
  /// GET /suivis/:type/:id/followers
  /// Retourne les données utilisateur complètes (charge les détails si nécessaire)
  static Future<List<Map<String, dynamic>>> getFollowers({
    required int entityId,
    required EntityType entityType,
  }) async {
    final endpoint = '/suivis/${entityType.value}/$entityId/followers';
    print('📤 [SuivreAuth] GET $endpoint');

    final response = await ApiService.get(endpoint);

    print('📥 [SuivreAuth] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> rawData = jsonResponse['data'] ?? [];
      print('📥 [SuivreAuth] ${rawData.length} followers récupérés');

      // Extraire et enrichir les données utilisateur
      final List<Map<String, dynamic>> followers = [];
      for (var item in rawData) {
        print('   📦 [SuivreAuth] Follower item keys: ${item.keys.toList()}');

        Map<String, dynamic>? userData;

        // Essayer différentes structures possibles
        if (item['user'] != null) {
          userData = Map<String, dynamic>.from(item['user']);
          print('   ✅ [SuivreAuth] Trouvé dans "user"');
        } else if (item['follower'] != null) {
          userData = Map<String, dynamic>.from(item['follower']);
          print('   ✅ [SuivreAuth] Trouvé dans "follower"');
        } else if (item['id'] != null && (item['nom'] != null || item['prenom'] != null)) {
          // Données utilisateur directement dans l'objet
          userData = Map<String, dynamic>.from(item);
          print('   ✅ [SuivreAuth] Données directes');
        } else if (item['user_id'] != null) {
          // Seulement user_id disponible, charger les détails
          final userId = item['user_id'];
          final userType = item['user_type'] ?? 'User';
          print('   🔄 [SuivreAuth] Chargement détails pour $userType #$userId...');

          try {
            if (userType == 'User') {
              final userResponse = await ApiService.get('/users/$userId');
              if (userResponse.statusCode == 200) {
                final userJson = jsonDecode(userResponse.body);
                userData = Map<String, dynamic>.from(userJson['data'] ?? userJson);
                print('   ✅ [SuivreAuth] Détails User #$userId chargés');
              }
            } else if (userType == 'Societe') {
              final societeResponse = await ApiService.get('/societes/$userId');
              if (societeResponse.statusCode == 200) {
                final societeJson = jsonDecode(societeResponse.body);
                userData = Map<String, dynamic>.from(societeJson['data'] ?? societeJson);
                print('   ✅ [SuivreAuth] Détails Societe #$userId chargés');
              }
            }
          } catch (e) {
            print('   ⚠️ [SuivreAuth] Erreur chargement détails $userType #$userId: $e');
          }
        }

        // Vérification robuste des données utilisateur
        if (userData != null) {
          // Vérifier que l'id est présent et valide (int ou string convertible)
          final id = userData['id'];
          if (id != null && (id is int || (id is String && int.tryParse(id) != null))) {
            // Convertir l'id en int si c'est une string
            if (id is String) {
              userData['id'] = int.parse(id);
            }
            followers.add(userData);
          } else {
            print('   ⚠️ [SuivreAuth] Données utilisateur sans id valide: $userData');
          }
        } else {
          print('   ⚠️ [SuivreAuth] Données utilisateur null, ignoré');
        }
      }

      print('📥 [SuivreAuth] ${followers.length} followers avec détails extraits');
      return followers;
    } else {
      print('❌ [SuivreAuth] Erreur getFollowers: ${response.body}');
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
  static Future<Map<String, dynamic>> getSocieteStats(int societeId) async {
    final response = await ApiService.get('/suivis/societe/$societeId/stats');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }
}
