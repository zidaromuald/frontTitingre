import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service.dart';
import '../AuthUS/auth_base_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Type de groupe (privé ou public)
enum GroupeType {
  prive('private'),
  public('public');

  final String value;
  const GroupeType(this.value);

  factory GroupeType.fromString(String value) {
    return GroupeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupeType.prive,
    );
  }
}

/// Catégorie de groupe (statut/type)
enum GroupeCategorie {
  simple('simple'),
  professionnel('professionnel'),
  supergroupe('supergroupe'),
  active('active'); // Statut actif retourné par le backend

  final String value;
  const GroupeCategorie(this.value);

  factory GroupeCategorie.fromString(String value) {
    return GroupeCategorie.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupeCategorie.simple,
    );
  }
}

/// Rôle d'un membre dans un groupe
enum MembreRole {
  membre('membre'),
  moderateur('moderateur'),
  admin('admin');

  final String value;
  const MembreRole(this.value);

  factory MembreRole.fromString(String value) {
    return MembreRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MembreRole.membre,
    );
  }
}

/// Statut d'un membre dans un groupe
enum MembreStatus {
  active('active'),
  suspended('suspended'),
  banned('banned');

  final String value;
  const MembreStatus(this.value);

  factory MembreStatus.fromString(String value) {
    return MembreStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MembreStatus.active,
    );
  }
}

/// Statut d'une invitation
enum InvitationStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired');

  final String value;
  const InvitationStatus(this.value);

  factory InvitationStatus.fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle GroupeProfil (photo de couverture, logo, description, règles)
class GroupeProfilModel {
  final int id;
  final int groupeId;
  final String? photoCouverture;
  final String? logo;
  final String? description;
  final String? regles;
  final List<String>? tags;
  final String? localisation;
  final String? languePrincipale;
  final String? secteurActivite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GroupeProfilModel({
    required this.id,
    required this.groupeId,
    this.photoCouverture,
    this.logo,
    this.description,
    this.regles,
    this.tags,
    this.localisation,
    this.languePrincipale,
    this.secteurActivite,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupeProfilModel.fromJson(Map<String, dynamic> json) {
    return GroupeProfilModel(
      id: json['id'],
      groupeId: json['groupe_id'],
      photoCouverture: json['photo_couverture'],
      logo: json['logo'],
      description: json['description'],
      regles: json['regles'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      localisation: json['localisation'],
      languePrincipale: json['langue_principale'],
      secteurActivite: json['secteur_activite'],
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
      if (description != null) 'description': description,
      if (regles != null) 'regles': regles,
      if (tags != null) 'tags': tags,
      if (localisation != null) 'localisation': localisation,
      if (languePrincipale != null) 'langue_principale': languePrincipale,
      if (secteurActivite != null) 'secteur_activite': secteurActivite,
    };
  }

  String? getPhotoCouvertureUrl() {
    if (photoCouverture == null) return null;
    if (photoCouverture!.startsWith('http')) return photoCouverture;
    return 'https://api.titingre.com/storage/$photoCouverture';
  }

  String? getLogoUrl() {
    if (logo == null) return null;
    if (logo!.startsWith('http')) return logo;
    return 'https://api.titingre.com/storage/$logo';
  }
}

/// Modèle GroupeUser (relation membre-groupe avec rôle et statut)
class GroupeUserModel {
  final int groupeId;
  final int userId;
  final MembreRole role;
  final MembreStatus status;
  final DateTime? joinedAt;
  final DateTime? updatedAt;

  GroupeUserModel({
    required this.groupeId,
    required this.userId,
    required this.role,
    required this.status,
    this.joinedAt,
    this.updatedAt,
  });

  factory GroupeUserModel.fromJson(Map<String, dynamic> json) {
    return GroupeUserModel(
      groupeId: json['groupe_id'],
      userId: json['user_id'],
      role: MembreRole.fromString(json['role'] ?? 'membre'),
      status: MembreStatus.fromString(json['status'] ?? 'active'),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupe_id': groupeId,
      'user_id': userId,
      'role': role.value,
      'status': status.value,
    };
  }

  bool isAdmin() => role == MembreRole.admin;
  bool isModerator() => role == MembreRole.moderateur;
  bool isActive() => status == MembreStatus.active;
}

/// Modèle GroupeInvitation
class GroupeInvitationModel {
  final int id;
  final int groupeId;
  final int invitedUserId;
  final int invitedByUserId;
  final InvitationStatus status;
  final String? message;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relations (optionnelles, chargées par le backend si include)
  final Map<String, dynamic>? groupe;
  final Map<String, dynamic>? invitedUser;
  final Map<String, dynamic>? invitedByUser;

  GroupeInvitationModel({
    required this.id,
    required this.groupeId,
    required this.invitedUserId,
    required this.invitedByUserId,
    required this.status,
    this.message,
    this.expiresAt,
    this.respondedAt,
    this.createdAt,
    this.updatedAt,
    this.groupe,
    this.invitedUser,
    this.invitedByUser,
  });

  factory GroupeInvitationModel.fromJson(Map<String, dynamic> json) {
    // Gérer les deux formats (snake_case et camelCase)
    final groupeId = json['groupe_id'] ?? json['groupeId'];
    final invitedUserId = json['invited_user_id'] ?? json['invitedUserId'];
    final invitedByUserId = json['invited_by_user_id'] ?? json['invitedByUserId'];
    final expiresAtStr = json['expires_at'] ?? json['expiresAt'];
    final respondedAtStr = json['responded_at'] ?? json['respondedAt'];
    final createdAtStr = json['created_at'] ?? json['createdAt'];
    final updatedAtStr = json['updated_at'] ?? json['updatedAt'];

    // Gérer plusieurs formats possibles pour les utilisateurs
    final invitedUserData = json['invited_user'] ??
                            json['invitedUser'] ??
                            json['user'] ??
                            json['invited'];
    final invitedByUserData = json['invited_by_user'] ??
                              json['invitedByUser'] ??
                              json['inviter'] ??
                              json['sender'];

    // Debug pour identifier le format de réponse
    print('🔍 [GroupeInvitationModel] Parsing invitation id=${json['id']}');
    print('   - invitedUser présent: ${invitedUserData != null}');
    print('   - invitedByUser présent: ${invitedByUserData != null}');
    if (invitedUserData != null) {
      print('   - invitedUser keys: ${invitedUserData.keys.toList()}');
    }
    if (invitedByUserData != null) {
      print('   - invitedByUser keys: ${invitedByUserData.keys.toList()}');
    }

    return GroupeInvitationModel(
      id: json['id'],
      groupeId: groupeId,
      invitedUserId: invitedUserId,
      invitedByUserId: invitedByUserId,
      status: InvitationStatus.fromString(json['status'] ?? 'pending'),
      message: json['message'],
      expiresAt: expiresAtStr != null ? DateTime.parse(expiresAtStr) : null,
      respondedAt: respondedAtStr != null ? DateTime.parse(respondedAtStr) : null,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : null,
      groupe: json['groupe'],
      invitedUser: invitedUserData,
      invitedByUser: invitedByUserData,
    );
  }

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool isPending() {
    return status == InvitationStatus.pending && !isExpired();
  }

  bool canBeAccepted() {
    return isPending();
  }

  // Helpers pour affichage
  String get groupeName => groupe?['nom'] ?? 'Groupe #$groupeId';

  String get invitedUserName {
    if (invitedUser == null) return 'Utilisateur #$invitedUserId';
    return _extractUserName(invitedUser!, 'Utilisateur #$invitedUserId');
  }

  String get invitedByUserName {
    if (invitedByUser == null) return 'Utilisateur #$invitedByUserId';
    return _extractUserName(invitedByUser!, 'Utilisateur #$invitedByUserId');
  }

  /// Méthode helper pour extraire le nom d'un utilisateur depuis ses données JSON
  /// Gère plusieurs formats de réponse (prenom/nom, first_name/last_name, etc.)
  String _extractUserName(Map<String, dynamic> userData, String fallback) {
    print('🔍 [GroupeInvitationModel] _extractUserName userData: $userData');

    // Essayer prenom/nom (format principal)
    final prenom = userData['prenom'] ?? userData['first_name'] ?? '';
    final nom = userData['nom'] ?? userData['last_name'] ?? userData['name'] ?? '';

    final fullName = '$prenom $nom'.trim();
    if (fullName.isNotEmpty) {
      print('🔍 [GroupeInvitationModel] Nom extrait: $fullName');
      return fullName;
    }

    // Fallback: essayer username ou email
    if (userData['username'] != null && userData['username'].toString().isNotEmpty) {
      print('🔍 [GroupeInvitationModel] Fallback username: ${userData['username']}');
      return userData['username'];
    }
    if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
      print('🔍 [GroupeInvitationModel] Fallback email: ${userData['email']}');
      return userData['email'];
    }

    print('🔍 [GroupeInvitationModel] Aucun nom trouvé, utilisation fallback: $fallback');
    return fallback;
  }
}

/// Modèle Groupe (groupe principal)
class GroupeModel {
  final int id;
  final String nom;
  final String? description;
  final int createdById;
  final String createdByType; // 'User' ou 'Societe'
  final GroupeType type;
  final int maxMembres;
  final GroupeCategorie categorie;
  final int? adminUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final GroupeProfilModel? profil;
  final int? membresCount;
  final String? myRole; // Rôle de l'utilisateur connecté dans ce groupe (membre, moderateur, admin)

  GroupeModel({
    required this.id,
    required this.nom,
    this.description,
    required this.createdById,
    required this.createdByType,
    required this.type,
    required this.maxMembres,
    required this.categorie,
    this.adminUserId,
    this.createdAt,
    this.updatedAt,
    this.profil,
    this.membresCount,
    this.myRole,
  });

  factory GroupeModel.fromJson(Map<String, dynamic> json) {
    // Gérer les deux formats de createdBy:
    // Format 1 (snake_case): created_by_id, created_by_type
    // Format 2 (camelCase objet): createdBy: {id, type}
    int createdById;
    String createdByType;

    if (json['created_by_id'] != null) {
      createdById = json['created_by_id'];
      createdByType = json['created_by_type'] ?? 'User';
    } else if (json['createdBy'] != null && json['createdBy'] is Map) {
      createdById = json['createdBy']['id'];
      createdByType = json['createdBy']['type'] ?? 'User';
    } else {
      // Fallback: utiliser l'id de l'auteur si disponible
      createdById = json['author_id'] ?? 0;
      createdByType = json['author_type'] ?? 'User';
    }

    // Gérer les deux formats de maxMembres
    final maxMembres = json['max_membres'] ?? json['maxMembres'] ?? 50;

    // Gérer les deux formats de membresCount
    final membresCount = json['membres_count'] ?? json['nombreMembres'];

    // Gérer les deux formats de adminUserId
    final adminUserId = json['admin_user_id'] ?? json['adminUserId'];

    // Gérer les deux formats de dates
    final createdAtStr = json['created_at'] ?? json['createdAt'];
    final updatedAtStr = json['updated_at'] ?? json['updatedAt'];

    return GroupeModel(
      id: json['id'],
      // IMPORTANT: Convertir en String pour éviter BindingError sur Flutter Web
      nom: (json['nom'] ?? 'Groupe sans nom').toString(),
      description: json['description']?.toString(),
      createdById: createdById,
      createdByType: createdByType,
      type: GroupeType.fromString(json['type'] ?? 'prive'),
      maxMembres: maxMembres,
      categorie: GroupeCategorie.fromString(json['categorie'] ?? 'simple'),
      adminUserId: adminUserId,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : null,
      profil: json['profil'] != null
          ? GroupeProfilModel.fromJson(json['profil'])
          : null,
      membresCount: membresCount,
      myRole: json['myRole'] ?? json['my_role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      if (description != null) 'description': description,
      'created_by_id': createdById,
      'created_by_type': createdByType,
      'type': type.value,
      'max_membres': maxMembres,
      'categorie': categorie.value,
      if (adminUserId != null) 'admin_user_id': adminUserId,
    };
  }

  bool isCreatedBySociete() => createdByType == 'Societe';
  bool isCreatedByUser() => createdByType == 'User';
  bool isPrive() => type == GroupeType.prive;
  bool isPublic() => type == GroupeType.public;

  bool isFull() {
    if (membresCount == null) return false;
    return membresCount! >= maxMembres;
  }

  String? getPhotoCouvertureUrl() => profil?.getPhotoCouvertureUrl();
  String? getLogoUrl() => profil?.getLogoUrl();

  // Helpers pour myRole
  bool get isMyRoleAdmin => myRole == 'admin';
  bool get isMyRoleModerator => myRole == 'moderateur';
  bool get isMyRoleMember => myRole == 'membre';
  bool get amIMember => myRole != null;
}

// ============================================================================
// SERVICE GROUPES
// ============================================================================

/// Service pour gérer les groupes (création, adhésion, invitations, etc.)
class GroupeAuthService {
  // ==========================================================================
  // STOCKAGE LOCAL DES GROUPES CRÉÉS
  // ==========================================================================

  static const String _createdGroupesKey = 'created_groupes_ids';

  /// Stocker l'ID d'un groupe créé localement
  static Future<void> _storeCreatedGroupeId(int groupeId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingIds = prefs.getStringList(_createdGroupesKey) ?? [];
    if (!existingIds.contains(groupeId.toString())) {
      existingIds.add(groupeId.toString());
      await prefs.setStringList(_createdGroupesKey, existingIds);
      print('💾 [GroupeService] ID groupe $groupeId stocké localement');
    }
  }

  /// Récupérer les IDs des groupes créés stockés localement
  static Future<List<int>> _getStoredCreatedGroupeIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_createdGroupesKey) ?? [];
    return ids.map((id) => int.parse(id)).toList();
  }

  // ==========================================================================
  // GESTION DES GROUPES
  // ==========================================================================

  /// Créer un nouveau groupe
  /// Note: Le créateur rejoint automatiquement le groupe comme admin après création
  static Future<GroupeModel> createGroupe({
    required String nom,
    String? description,
    GroupeType type = GroupeType.prive,
    int maxMembres = 50,
  }) async {
    final data = {
      'nom': nom,
      if (description != null) 'description': description,
      'type': type.value,
      // Note: max_membres n'est plus envoyé - géré côté backend
    };

    print('📤 [GroupeService] Création groupe: $nom');
    final response = await ApiService.post('/groupes', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      // Le backend retourne 'groupe' et non 'data'
      final groupeData = jsonResponse['groupe'] ?? jsonResponse['data'];
      if (groupeData == null) {
        throw Exception('Réponse invalide du serveur');
      }
      final groupe = GroupeModel.fromJson(groupeData);
      print('✅ [GroupeService] Groupe créé: id=${groupe.id}, nom=${groupe.nom}');

      // IMPORTANT: Stocker l'ID du groupe créé localement pour le récupérer plus tard
      // Cela permet de contourner le problème où /groupes/me ne retourne pas les groupes
      // créés si le créateur n'est pas automatiquement ajouté comme membre
      await _storeCreatedGroupeId(groupe.id);

      // IMPORTANT: Rejoindre automatiquement le groupe créé pour apparaître dans /groupes/me
      // Le backend devrait le faire automatiquement mais ce n'est pas toujours le cas
      try {
        print('📤 [GroupeService] Auto-join du groupe créé #${groupe.id}');
        final joinResponse = await ApiService.post(
          '/groupes/${groupe.id}/membres/join',
          {},
        );
        if (joinResponse.statusCode == 200 || joinResponse.statusCode == 201) {
          print('✅ [GroupeService] Auto-join réussi');
        } else {
          // Erreur 409 = déjà membre, c'est OK
          print('⚠️ [GroupeService] Auto-join status: ${joinResponse.statusCode} (peut-être déjà membre)');
        }
      } catch (e) {
        // Ne pas échouer si le join échoue (l'utilisateur peut être déjà membre)
        print('⚠️ [GroupeService] Auto-join échoué (ignoré): $e');
      }

      return groupe;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de création du groupe');
    }
  }

  /// Récupérer un groupe par ID
  static Future<GroupeModel> getGroupe(int groupeId) async {
    print('📤 [GroupeService] GET /groupes/$groupeId');
    try {
      final response = await ApiService.get('/groupes/$groupeId');
      print('📥 [GroupeService] Response status: ${response.statusCode}');
      print('📥 [GroupeService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Le backend peut retourner 'data' ou 'groupe' ou directement les données
        final groupeData = jsonResponse['data'] ?? jsonResponse['groupe'] ?? jsonResponse;
        print('📥 [GroupeService] Groupe data: $groupeData');
        return GroupeModel.fromJson(groupeData);
      } else {
        final error = jsonDecode(response.body);
        print('❌ [GroupeService] Erreur getGroupe: status=${response.statusCode}, message=${error['message']}');
        throw Exception(error['message'] ?? 'Groupe introuvable');
      }
    } catch (e) {
      print('❌ [GroupeService] Exception lors de getGroupe($groupeId): $e');
      rethrow;
    }
  }

  /// Mettre à jour un groupe
  static Future<GroupeModel> updateGroupe(
    int groupeId,
    Map<String, dynamic> updates,
  ) async {
    final response = await ApiService.put('/groupes/$groupeId', updates);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Le backend peut retourner 'data' ou 'groupe'
      final groupeData = jsonResponse['data'] ?? jsonResponse['groupe'] ?? jsonResponse;
      return GroupeModel.fromJson(groupeData);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour du groupe');
    }
  }

  /// Supprimer un groupe
  static Future<void> deleteGroupe(int groupeId) async {
    final response = await ApiService.delete('/groupes/$groupeId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de suppression du groupe');
    }
  }

  /// Rechercher des groupes
  ///
  /// Paramètres :
  /// - [query] : Recherche par nom ou description (optionnel si [tags] est fourni)
  /// - [tags] : Filtre par tags/catégories (ex: ['Agriculture', 'Élevage'])
  /// - [type] : Filtre par type (public/prive)
  /// - [limit] : Nombre maximum de résultats
  /// - [offset] : Décalage pour la pagination
  static Future<List<GroupeModel>> searchGroupes({
    String? query,
    List<String>? tags,
    String? type,
    int? limit,
    int? offset,
  }) async {
    final params = <String>[];
    // Encoder les paramètres de recherche pour éviter les problèmes avec espaces et caractères spéciaux
    if (query != null && query.isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(query)}');
    }
    if (tags != null && tags.isNotEmpty) {
      // Encoder chaque tag séparément puis joindre
      final encodedTags = tags.map((t) => Uri.encodeQueryComponent(t)).join(',');
      params.add('tags=$encodedTags');
    }
    if (type != null) params.add('type=$type');
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final endpoint = '/groupes/search/query$queryString';

    print('🔍 [GroupeAuth] Search groupes: $endpoint');
    final response = await ApiService.get(endpoint);

    print('🔍 [GroupeAuth] Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Le backend peut retourner 'data' ou 'groupes'
      final List<dynamic> groupesData = jsonResponse['data'] ?? jsonResponse['groupes'] ?? [];
      print('🔍 [GroupeAuth] Groupes data count: ${groupesData.length}');
      return groupesData.map((json) => GroupeModel.fromJson(json)).toList();
    } else {
      print('❌ [GroupeAuth] Erreur: ${response.body}');
      throw Exception('Erreur de recherche: ${response.statusCode}');
    }
  }

  // ==========================================================================
  // NOTE: Les méthodes suivantes ont été déplacées vers des services dédiés :
  // - Gestion des membres → GroupeMembreService
  // - Gestion des invitations → GroupeInvitationService
  // - Gestion du profil → GroupeProfilService
  // ==========================================================================

  // ==========================================================================
  // UTILITAIRES
  // ==========================================================================

  /// Récupérer les groupes auxquels je participe (créés + membre)
  /// Fonctionne pour les Users ET les Sociétés via le token d'authentification
  static Future<List<GroupeModel>> getMyGroupes() async {
    print('📤 [GroupeService] Appel GET /groupes/me');

    try {
      final response = await ApiService.get('/groupes/me');
      print('📥 [GroupeService] Response status: ${response.statusCode}');
      print('📥 [GroupeService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Le backend peut retourner 'data' ou 'groupes'
        final List<dynamic> groupesData = jsonResponse['data'] ?? jsonResponse['groupes'] ?? [];
        print('📥 [GroupeService] Nombre de groupes via /groupes/me: ${groupesData.length}');

        if (groupesData.isNotEmpty) {
          return groupesData.map((json) => GroupeModel.fromJson(json)).toList();
        }

        // Si 0 groupes retournés, essayer d'autres endpoints comme fallback
        print('⚠️ [GroupeService] /groupes/me retourne 0 groupes, tentative fallbacks...');
      }
    } catch (e) {
      print('⚠️ [GroupeService] Erreur /groupes/me: $e');
    }

    // Fallback 1: Essayer /users/me/groupes
    try {
      print('📤 [GroupeService] Fallback 1: GET /users/me/groupes');
      final response = await ApiService.get('/users/me/groupes');
      print('📥 [GroupeService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> groupesData = jsonResponse['data'] ?? jsonResponse['groupes'] ?? [];
        print('📥 [GroupeService] Nombre de groupes via /users/me/groupes: ${groupesData.length}');

        if (groupesData.isNotEmpty) {
          return groupesData.map((json) => GroupeModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('⚠️ [GroupeService] Fallback 1 échoué: $e');
    }

    // Fallback 2: Essayer /societes/me/groupes
    try {
      print('📤 [GroupeService] Fallback 2: GET /societes/me/groupes');
      final response = await ApiService.get('/societes/me/groupes');
      print('📥 [GroupeService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> groupesData = jsonResponse['data'] ?? jsonResponse['groupes'] ?? [];
        print('📥 [GroupeService] Nombre de groupes via /societes/me/groupes: ${groupesData.length}');

        if (groupesData.isNotEmpty) {
          return groupesData.map((json) => GroupeModel.fromJson(json)).toList();
        }
      }
    } catch (e) {
      print('⚠️ [GroupeService] Fallback 2 échoué: $e');
    }

    print('❌ [GroupeService] Aucun groupe trouvé avec tous les fallbacks');
    return [];
  }

  /// Récupérer les groupes pour une SOCIÉTÉ
  /// DEPRECATED: Utilisez getMyGroupes() directement - fonctionne pour Users ET Sociétés
  /// Cette méthode est maintenue pour compatibilité mais délègue à getMyGroupes()
  static Future<List<GroupeModel>> getMySocieteGroupes(int societeId) async {
    print('📤 [GroupeService] getMySocieteGroupes($societeId) - délégation à getMyGroupes()');
    return getMyGroupes();
  }

  /// Récupérer uniquement les groupes que j'ai CRÉÉS
  /// Utilise /groupes/created ou /groupes?createdById=X pour récupérer directement les groupes créés
  /// Fonctionne pour les Users ET les Sociétés
  static Future<List<GroupeModel>> getMyCreatedGroupes() async {
    try {
      // Récupérer l'utilisateur/société courant(e) depuis les données stockées localement
      final userData = await AuthBaseService.getUserData();
      if (userData == null) {
        print('❌ [GroupeService] Aucune donnée utilisateur stockée localement');
        throw Exception('Utilisateur non connecté');
      }
      final currentUserId = userData['id'];
      if (currentUserId == null) {
        print('❌ [GroupeService] ID utilisateur non trouvé dans les données stockées');
        throw Exception('ID utilisateur non trouvé');
      }

      // Utiliser le type stocké lors de la connexion (fiable)
      final storedType = await AuthBaseService.getUserType();
      // Convertir 'societe' -> 'Societe' et 'user' -> 'User' (format backend)
      String currentUserType = storedType == 'societe' ? 'Societe' : 'User';
      print('📤 [GroupeService] getMyCreatedGroupes - currentUserId: $currentUserId, storedType: $storedType, currentUserType: $currentUserType');

      // Stratégie: Combiner les groupes de /groupes/me avec un appel pour récupérer les groupes créés
      // car /groupes/me ne retourne que les groupes où on est MEMBRE, pas ceux qu'on a CRÉÉS

      final Map<int, GroupeModel> groupesMap = {};

      // 1. Essayer de récupérer les groupes créés via /groupes/created
      try {
        print('📤 [GroupeService] Tentative GET /groupes/created');
        final createdResponse = await ApiService.get('/groupes/created');
        print('📥 [GroupeService] /groupes/created status: ${createdResponse.statusCode}');

        if (createdResponse.statusCode == 200) {
          final jsonResponse = jsonDecode(createdResponse.body);
          final List<dynamic> groupesData = jsonResponse['data'] ?? jsonResponse['groupes'] ?? [];
          print('📥 [GroupeService] ${groupesData.length} groupes créés via /groupes/created');

          for (var json in groupesData) {
            final groupe = GroupeModel.fromJson(json);
            groupesMap[groupe.id] = groupe;
          }
        }
      } catch (e) {
        print('⚠️ [GroupeService] /groupes/created non disponible: $e');
      }

      // 2. Récupérer TOUS les groupes publics et filtrer côté frontend
      // Car le backend ne supporte pas le filtre createdById/createdByType
      try {
        print('📤 [GroupeService] GET /groupes (tous les groupes publics)');
        final allGroupesResponse = await ApiService.get('/groupes?limit=100');
        print('📥 [GroupeService] /groupes status: ${allGroupesResponse.statusCode}');

        if (allGroupesResponse.statusCode == 200) {
          final jsonResponse = jsonDecode(allGroupesResponse.body);
          final List<dynamic> groupesData = jsonResponse['data'] ?? jsonResponse['groupes'] ?? [];
          print('📥 [GroupeService] ${groupesData.length} groupes totaux récupérés');

          // Filtrer côté frontend les groupes créés par moi
          for (var json in groupesData) {
            final groupe = GroupeModel.fromJson(json);
            final isCreatedByMe = groupe.createdById == currentUserId &&
                groupe.createdByType == currentUserType;
            if (isCreatedByMe) {
              groupesMap[groupe.id] = groupe;
              print('   + Trouvé groupe créé par moi: ${groupe.nom}');
            }
          }
          print('📥 [GroupeService] ${groupesMap.length} groupes créés par moi après filtrage');
        }
      } catch (e) {
        print('⚠️ [GroupeService] /groupes non disponible: $e');
      }

      // 3. Récupérer les groupes stockés localement (créés par cette session/appareil)
      // Cela permet de récupérer les groupes créés même si le backend n'a pas ajouté
      // le créateur comme membre automatiquement
      final storedIds = await _getStoredCreatedGroupeIds();
      print('📤 [GroupeService] ${storedIds.length} IDs de groupes stockés localement');

      for (var groupeId in storedIds) {
        if (!groupesMap.containsKey(groupeId)) {
          try {
            print('📤 [GroupeService] Récupération groupe #$groupeId via /groupes/$groupeId');
            final groupe = await getGroupe(groupeId);
            // Vérifier que ce groupe a bien été créé par moi
            if (groupe.createdById == currentUserId &&
                groupe.createdByType == currentUserType) {
              groupesMap[groupeId] = groupe;
              print('   + Ajouté depuis stockage local: ${groupe.nom}');
            }
          } catch (e) {
            print('   ⚠️ Groupe #$groupeId non trouvé ou erreur: $e');
          }
        }
      }

      // 4. Fallback: Filtrer les groupes de /groupes/me (ancien comportement)
      // Cela récupère les groupes où je suis membre ET que j'ai créés
      final allMyGroupes = await getMyGroupes();
      print('📤 [GroupeService] getMyGroupes retourne ${allMyGroupes.length} groupes');

      for (var groupe in allMyGroupes) {
        final isCreatedByMe = groupe.createdById == currentUserId &&
            groupe.createdByType == currentUserType;
        if (isCreatedByMe && !groupesMap.containsKey(groupe.id)) {
          groupesMap[groupe.id] = groupe;
          print('   + Ajouté depuis /groupes/me: ${groupe.nom}');
        }
      }

      final result = groupesMap.values.toList();
      print('📤 [GroupeService] getMyCreatedGroupes - total: ${result.length} groupes créés');

      for (var groupe in result) {
        print('   - ${groupe.nom}: createdBy=${groupe.createdByType} #${groupe.createdById}');
      }

      return result;
    } catch (e) {
      print('❌ Erreur getMyCreatedGroupes: $e');
      return [];
    }
  }

  /// Vérifier si je suis membre d'un groupe
  static Future<bool> isMember(int groupeId) async {
    try {
      print('📤 [GroupeService] Vérification membership: GET /groupes/$groupeId/is-member');
      final response = await ApiService.get('/groupes/$groupeId/is-member');
      print('📥 [GroupeService] is-member response status: ${response.statusCode}');
      print('📥 [GroupeService] is-member response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final isMember = jsonResponse['data']?['is_member'] ?? jsonResponse['is_member'] ?? false;
        print('📥 [GroupeService] is_member parsed: $isMember');
        return isMember;
      }
      return false;
    } catch (e) {
      print('❌ [GroupeService] Erreur isMember: $e');
      return false;
    }
  }

  /// Récupérer mon rôle dans un groupe
  static Future<MembreRole?> getMyRole(int groupeId) async {
    try {
      print('📤 [GroupeService] Récupération rôle: GET /groupes/$groupeId/my-role');
      final response = await ApiService.get('/groupes/$groupeId/my-role');
      print('📥 [GroupeService] my-role response status: ${response.statusCode}');
      print('📥 [GroupeService] my-role response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final roleStr = jsonResponse['data']?['role'] ?? jsonResponse['role'];
        print('📥 [GroupeService] role parsed: $roleStr');
        return roleStr != null ? MembreRole.fromString(roleStr) : null;
      }
      return null;
    } catch (e) {
      print('❌ [GroupeService] Erreur getMyRole: $e');
      return null;
    }
  }
}
