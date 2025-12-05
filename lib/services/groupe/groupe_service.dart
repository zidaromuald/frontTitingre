import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Type de groupe (privé ou public)
enum GroupeType {
  prive('prive'),
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

/// Catégorie de groupe selon le nombre de membres
enum GroupeCategorie {
  simple('simple'), // <= 100 membres
  professionnel('professionnel'), // 101-9999 membres
  supergroupe('supergroupe'); // >= 10000 membres

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
    return photoCouverture != null ? '/storage/$photoCouverture' : null;
  }

  String? getLogoUrl() {
    return logo != null ? '/storage/$logo' : null;
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
  });

  factory GroupeInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupeInvitationModel(
      id: json['id'],
      groupeId: json['groupe_id'],
      invitedUserId: json['invited_user_id'],
      invitedByUserId: json['invited_by_user_id'],
      status: InvitationStatus.fromString(json['status'] ?? 'pending'),
      message: json['message'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
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
    return GroupeModel(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      createdById: json['created_by_id'],
      createdByType: json['created_by_type'],
      type: GroupeType.fromString(json['type'] ?? 'prive'),
      maxMembres: json['max_membres'] ?? 50,
      categorie: GroupeCategorie.fromString(json['categorie'] ?? 'simple'),
      adminUserId: json['admin_user_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      profil: json['profil'] != null
          ? GroupeProfilModel.fromJson(json['profil'])
          : null,
      membresCount: json['membres_count'],
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
      'max_membres': maxMembres,
    };

    final response = await ApiService.post('/groupes', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de création du groupe');
    }
  }

  /// Récupérer un groupe par ID
  static Future<GroupeModel> getGroupe(int groupeId) async {
    final response = await ApiService.get('/groupes/$groupeId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Groupe introuvable');
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
      return GroupeModel.fromJson(jsonResponse['data']);
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
  static Future<List<GroupeModel>> searchGroupes({
    required String query,
    int? limit,
    int? offset,
  }) async {
    final params = <String>[];
    params.add('q=$query');
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get('/groupes/search/query$queryString');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> groupesData = jsonResponse['data'];
      return groupesData.map((json) => GroupeModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de recherche');
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

  /// Récupérer les groupes auxquels je participe
  static Future<List<GroupeModel>> getMyGroupes() async {
    final response = await ApiService.get('/groupes/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> groupesData = jsonResponse['data'];
      return groupesData.map((json) => GroupeModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des groupes');
    }
  }

  /// Vérifier si je suis membre d'un groupe
  static Future<bool> isMember(int groupeId) async {
    try {
      final response = await ApiService.get('/groupes/$groupeId/is-member');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['is_member'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer mon rôle dans un groupe
  static Future<MembreRole?> getMyRole(int groupeId) async {
    try {
      final response = await ApiService.get('/groupes/$groupeId/my-role');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final roleStr = jsonResponse['data']['role'];
        return roleStr != null ? MembreRole.fromString(roleStr) : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
