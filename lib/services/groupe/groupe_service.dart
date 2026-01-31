import 'dart:convert';
import '../api_service.dart';

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
}

// ============================================================================
// SERVICE GROUPES
// ============================================================================

/// Service pour gérer les groupes (création, adhésion, invitations, etc.)
class GroupeAuthService {
  // ==========================================================================
  // GESTION DES GROUPES
  // ==========================================================================

  /// Créer un nouveau groupe
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

    final response = await ApiService.post('/groupes', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      // Le backend retourne 'groupe' et non 'data'
      final groupeData = jsonResponse['groupe'] ?? jsonResponse['data'];
      if (groupeData == null) {
        throw Exception('Réponse invalide du serveur');
      }
      return GroupeModel.fromJson(groupeData);
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
    if (query != null && query.isNotEmpty) params.add('q=$query');
    if (tags != null && tags.isNotEmpty) {
      // Envoyer les tags sous forme de liste séparée par virgules
      params.add('tags=${tags.join(',')}');
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
  static Future<List<GroupeModel>> getMyGroupes() async {
    print('📤 [GroupeService] Appel GET /groupes/me');
    final response = await ApiService.get('/groupes/me');
    print('📥 [GroupeService] Response status: ${response.statusCode}');
    print('📥 [GroupeService] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      // Le backend peut retourner 'data' ou 'groupes'
      final List<dynamic> groupesData = jsonResponse['data'] ?? jsonResponse['groupes'] ?? [];
      print('📥 [GroupeService] Nombre de groupes: ${groupesData.length}');
      return groupesData.map((json) => GroupeModel.fromJson(json)).toList();
    } else {
      print('❌ [GroupeService] Erreur: ${response.body}');
      throw Exception('Erreur de récupération des groupes');
    }
  }

  /// Récupérer uniquement les groupes que j'ai CRÉÉS
  /// Filtre les groupes où createdById == userId courant
  static Future<List<GroupeModel>> getMyCreatedGroupes() async {
    try {
      // Récupérer l'utilisateur courant
      final currentUser = await ApiService.get('/auth/me');
      if (currentUser.statusCode != 200) {
        throw Exception('Impossible de récupérer l\'utilisateur courant');
      }
      final userData = jsonDecode(currentUser.body);
      final currentUserId = userData['data']?['id'] ?? userData['id'];

      // Récupérer tous mes groupes
      final allMyGroupes = await getMyGroupes();

      // Filtrer pour ne garder que ceux que j'ai créés
      return allMyGroupes
          .where((groupe) =>
              groupe.createdById == currentUserId &&
              groupe.createdByType == 'User')
          .toList();
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
