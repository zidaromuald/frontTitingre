import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Statut d'un abonnement
enum AbonnementStatut {
  actif('actif'),
  suspendu('suspendu'),
  expire('expire'),
  annule('annule');

  final String value;
  const AbonnementStatut(this.value);

  factory AbonnementStatut.fromString(String value) {
    return AbonnementStatut.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AbonnementStatut.actif,
    );
  }
}

/// Permissions pour un abonnement
enum AbonnementPermission {
  voirProfil('voir_profil'),
  voirContacts('voir_contacts'),
  voirProjets('voir_projets'),
  messagerie('messagerie'),
  notifications('notifications');

  final String value;
  const AbonnementPermission(this.value);

  factory AbonnementPermission.fromString(String value) {
    return AbonnementPermission.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AbonnementPermission.voirProfil,
    );
  }
}

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle d'abonnement
class AbonnementModel {
  final int id;
  final int userId;
  final int societeId;
  final AbonnementStatut statut;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? planCollaboration;
  final List<String>? permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations optionnelles (peuvent être incluses selon l'endpoint)
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? societe;

  AbonnementModel({
    required this.id,
    required this.userId,
    required this.societeId,
    required this.statut,
    this.dateDebut,
    this.dateFin,
    this.planCollaboration,
    this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.societe,
  });

  factory AbonnementModel.fromJson(Map<String, dynamic> json) {
    return AbonnementModel(
      id: json['id'],
      userId: json['user_id'],
      societeId: json['societe_id'],
      statut: AbonnementStatut.fromString(json['statut'] ?? 'actif'),
      dateDebut:
          json['date_debut'] != null ? DateTime.parse(json['date_debut']) : null,
      dateFin: json['date_fin'] != null ? DateTime.parse(json['date_fin']) : null,
      planCollaboration: json['plan_collaboration'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'],
      societe: json['societe'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'societe_id': societeId,
      'statut': statut.value,
      if (dateDebut != null) 'date_debut': dateDebut!.toIso8601String(),
      if (dateFin != null) 'date_fin': dateFin!.toIso8601String(),
      if (planCollaboration != null) 'plan_collaboration': planCollaboration,
      if (permissions != null) 'permissions': permissions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthodes helper
  bool isActif() => statut == AbonnementStatut.actif;
  bool isSuspendu() => statut == AbonnementStatut.suspendu;
  bool isExpire() => statut == AbonnementStatut.expire;
  bool isAnnule() => statut == AbonnementStatut.annule;

  bool hasPermission(AbonnementPermission permission) {
    if (permissions == null) return false;
    return permissions!.contains(permission.value);
  }
}

/// Statistiques d'abonnement
class AbonnementStats {
  final int total;
  final int actifs;
  final int suspendus;
  final int expires;
  final int annules;

  AbonnementStats({
    required this.total,
    required this.actifs,
    required this.suspendus,
    required this.expires,
    required this.annules,
  });

  factory AbonnementStats.fromJson(Map<String, dynamic> json) {
    return AbonnementStats(
      total: json['total'] ?? 0,
      actifs: json['actifs'] ?? 0,
      suspendus: json['suspendus'] ?? 0,
      expires: json['expires'] ?? 0,
      annules: json['annules'] ?? 0,
    );
  }
}

// ============================================================================
// SERVICE ABONNEMENTS
// ============================================================================

/// Service pour gérer les abonnements entre utilisateurs et sociétés
class AbonnementAuthService {
  // ==========================================================================
  // CONSULTATION DES ABONNEMENTS
  // ==========================================================================

  /// Récupérer mes abonnements (utilisateur)
  /// GET /abonnements/my-subscriptions?statut=actif
  /// Réservé aux utilisateurs (userType: 'user')
  static Future<List<AbonnementModel>> getMySubscriptions({
    AbonnementStatut? statut,
  }) async {
    final queryString = statut != null ? '?statut=${statut.value}' : '';
    final response = await ApiService.get(
      '/abonnements/my-subscriptions$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> abonnementsData = jsonResponse['data'];
      return abonnementsData
          .map((json) => AbonnementModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des abonnements');
    }
  }

  /// Récupérer mes abonnés (société)
  /// GET /abonnements/my-subscribers?statut=actif
  /// Réservé aux sociétés (userType: 'societe')
  static Future<List<AbonnementModel>> getMySubscribers({
    AbonnementStatut? statut,
  }) async {
    final queryString = statut != null ? '?statut=${statut.value}' : '';
    final response = await ApiService.get(
      '/abonnements/my-subscribers$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> abonnementsData = jsonResponse['data'];
      return abonnementsData
          .map((json) => AbonnementModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des abonnés');
    }
  }

  /// Vérifier si un abonnement existe entre moi et une société
  /// GET /abonnements/check/:societeId
  /// Réservé aux utilisateurs
  static Future<Map<String, dynamic>> checkAbonnement(int societeId) async {
    final response = await ApiService.get('/abonnements/check/$societeId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data'];
    } else {
      throw Exception('Erreur de vérification de l\'abonnement');
    }
  }

  /// Récupérer un abonnement spécifique par ID
  /// GET /abonnements/:id
  static Future<AbonnementModel> getAbonnement(int abonnementId) async {
    final response = await ApiService.get('/abonnements/$abonnementId');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AbonnementModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Abonnement introuvable');
    }
  }

  // ==========================================================================
  // GESTION DES ABONNEMENTS
  // ==========================================================================

  /// Mettre à jour un abonnement
  /// PUT /abonnements/:id
  /// Réservé à la société propriétaire
  static Future<AbonnementModel> updateAbonnement(
    int abonnementId, {
    String? planCollaboration,
    DateTime? dateFin,
  }) async {
    final data = <String, dynamic>{};
    if (planCollaboration != null) {
      data['plan_collaboration'] = planCollaboration;
    }
    if (dateFin != null) {
      data['date_fin'] = dateFin.toIso8601String().split('T')[0];
    }

    final response = await ApiService.put('/abonnements/$abonnementId', data);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AbonnementModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de mise à jour de l\'abonnement',
      );
    }
  }

  /// Mettre à jour les permissions d'un abonnement
  /// PUT /abonnements/:id/permissions
  /// Réservé à la société propriétaire
  static Future<AbonnementModel> updatePermissions(
    int abonnementId,
    List<String> permissions,
  ) async {
    final data = {'permissions': permissions};

    final response = await ApiService.put(
      '/abonnements/$abonnementId/permissions',
      data,
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AbonnementModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de mise à jour des permissions',
      );
    }
  }

  /// Suspendre un abonnement
  /// PUT /abonnements/:id/suspend
  /// Réservé à la société propriétaire
  static Future<AbonnementModel> suspendAbonnement(int abonnementId) async {
    final response = await ApiService.put(
      '/abonnements/$abonnementId/suspend',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AbonnementModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de suspension');
    }
  }

  /// Réactiver un abonnement suspendu
  /// PUT /abonnements/:id/reactivate
  /// Réservé à la société propriétaire
  static Future<AbonnementModel> reactivateAbonnement(int abonnementId) async {
    final response = await ApiService.put(
      '/abonnements/$abonnementId/reactivate',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AbonnementModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de réactivation');
    }
  }

  /// Supprimer (annuler) un abonnement
  /// DELETE /abonnements/:id
  /// Accessible par l'utilisateur OU la société
  static Future<void> deleteAbonnement(int abonnementId) async {
    final response = await ApiService.delete('/abonnements/$abonnementId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de suppression');
    }
  }

  // ==========================================================================
  // STATISTIQUES
  // ==========================================================================

  /// Récupérer mes statistiques d'abonnements (utilisateur)
  /// GET /abonnements/stats/my-subscriptions
  /// Réservé aux utilisateurs
  static Future<AbonnementStats> getMySubscriptionStats() async {
    final response = await ApiService.get(
      '/abonnements/stats/my-subscriptions',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AbonnementStats.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }

  /// Récupérer mes statistiques d'abonnés (société)
  /// GET /abonnements/stats/my-subscribers
  /// Réservé aux sociétés
  static Future<AbonnementStats> getMySubscriberStats() async {
    final response = await ApiService.get(
      '/abonnements/stats/my-subscribers',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AbonnementStats.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Récupérer tous mes abonnements actifs (utilisateur)
  static Future<List<AbonnementModel>> getActiveSubscriptions() async {
    return getMySubscriptions(statut: AbonnementStatut.actif);
  }

  /// Récupérer tous mes abonnés actifs (société)
  static Future<List<AbonnementModel>> getActiveSubscribers() async {
    return getMySubscribers(statut: AbonnementStatut.actif);
  }

  /// Vérifier si je suis abonné à une société
  static Future<bool> isSubscribedTo(int societeId) async {
    try {
      final result = await checkAbonnement(societeId);
      return result['is_abonne'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer l'abonnement avec une société spécifique
  static Future<AbonnementModel?> getSubscriptionWithSociete(
    int societeId,
  ) async {
    try {
      final subscriptions = await getMySubscriptions();
      return subscriptions.firstWhere(
        (abonnement) => abonnement.societeId == societeId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Convertir une liste de permissions enum en liste de strings
  static List<String> permissionsToStrings(
    List<AbonnementPermission> permissions,
  ) {
    return permissions.map((p) => p.value).toList();
  }

  /// Convertir une liste de strings en liste de permissions enum
  static List<AbonnementPermission> stringsToPermissions(
    List<String> permissions,
  ) {
    return permissions
        .map((s) => AbonnementPermission.fromString(s))
        .toList();
  }
}
