import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Statut d'une demande d'abonnement
enum DemandeAbonnementStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled');

  final String value;
  const DemandeAbonnementStatus(this.value);

  factory DemandeAbonnementStatus.fromString(String value) {
    return DemandeAbonnementStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DemandeAbonnementStatus.pending,
    );
  }
}

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle de demande d'abonnement
class DemandeAbonnementModel {
  final int id;
  final int userId;
  final int societeId;
  final DemandeAbonnementStatus status;
  final String? message;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations optionnelles (peuvent être incluses selon l'endpoint)
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? societe;

  DemandeAbonnementModel({
    required this.id,
    required this.userId,
    required this.societeId,
    required this.status,
    this.message,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.societe,
  });

  factory DemandeAbonnementModel.fromJson(Map<String, dynamic> json) {
    return DemandeAbonnementModel(
      id: json['id'],
      userId: json['user_id'],
      societeId: json['societe_id'],
      status: DemandeAbonnementStatus.fromString(json['status'] ?? 'pending'),
      message: json['message'],
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
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
      'status': status.value,
      if (message != null) 'message': message,
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthodes helper
  bool isPending() => status == DemandeAbonnementStatus.pending;
  bool isAccepted() => status == DemandeAbonnementStatus.accepted;
  bool isDeclined() => status == DemandeAbonnementStatus.declined;
  bool isCancelled() => status == DemandeAbonnementStatus.cancelled;
}

/// Réponse lors de l'acceptation d'une demande
class AcceptDemandeResponse {
  final DemandeAbonnementModel demande;
  final int suivresCreated;
  final int abonnementId;
  final int pagePartenariatId;

  AcceptDemandeResponse({
    required this.demande,
    required this.suivresCreated,
    required this.abonnementId,
    required this.pagePartenariatId,
  });

  factory AcceptDemandeResponse.fromJson(Map<String, dynamic> json) {
    return AcceptDemandeResponse(
      demande: DemandeAbonnementModel.fromJson(json['demande']),
      suivresCreated: json['suivres_created'],
      abonnementId: json['abonnement_id'],
      pagePartenariatId: json['page_partenariat_id'],
    );
  }
}

// ============================================================================
// SERVICE DEMANDES D'ABONNEMENT
// ============================================================================

/// Service pour gérer les demandes d'abonnement entre utilisateurs et sociétés
class DemandeAbonnementService {
  // ==========================================================================
  // ENVOI DE DEMANDES (USER uniquement)
  // ==========================================================================

  /// Envoyer une demande d'abonnement à une société
  /// POST /demandes-abonnement
  /// Réservé aux utilisateurs (userType: 'user')
  static Future<DemandeAbonnementModel> envoyerDemande({
    required int societeId,
    String? message,
  }) async {
    final data = {
      'societe_id': societeId,
      if (message != null) 'message': message,
    };

    final response = await ApiService.post('/demandes-abonnement', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return DemandeAbonnementModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de l\'envoi de la demande',
      );
    }
  }

  /// Annuler une demande d'abonnement (par l'utilisateur qui l'a envoyée)
  /// DELETE /demandes-abonnement/:id
  /// Réservé aux utilisateurs
  static Future<void> annulerDemande(int demandeId) async {
    final response = await ApiService.delete('/demandes-abonnement/$demandeId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'annulation');
    }
  }

  /// Récupérer mes demandes envoyées
  /// GET /demandes-abonnement/sent?status=pending
  /// Réservé aux utilisateurs
  static Future<List<DemandeAbonnementModel>> getMesDemandesEnvoyees({
    DemandeAbonnementStatus? status,
  }) async {
    final queryString = status != null ? '?status=${status.value}' : '';
    final response = await ApiService.get(
      '/demandes-abonnement/sent$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> demandesData = jsonResponse['data'];
      return demandesData
          .map((json) => DemandeAbonnementModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des demandes envoyées');
    }
  }

  // ==========================================================================
  // GESTION DES DEMANDES (SOCIETE uniquement)
  // ==========================================================================

  /// Accepter une demande d'abonnement
  /// PUT /demandes-abonnement/:id/accept
  /// Crée: Suivre + Abonnement + PagePartenariat en une transaction
  /// Réservé aux sociétés (userType: 'societe')
  static Future<AcceptDemandeResponse> accepterDemande(int demandeId) async {
    final response = await ApiService.put(
      '/demandes-abonnement/$demandeId/accept',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AcceptDemandeResponse.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'acceptation');
    }
  }

  /// Refuser une demande d'abonnement
  /// PUT /demandes-abonnement/:id/decline
  /// Réservé aux sociétés
  static Future<DemandeAbonnementModel> refuserDemande(int demandeId) async {
    final response = await ApiService.put(
      '/demandes-abonnement/$demandeId/decline',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return DemandeAbonnementModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors du refus');
    }
  }

  /// Récupérer les demandes reçues par la société connectée
  /// GET /demandes-abonnement/received?status=pending
  /// Réservé aux sociétés
  static Future<List<DemandeAbonnementModel>> getDemandesRecues({
    DemandeAbonnementStatus? status,
  }) async {
    final queryString = status != null ? '?status=${status.value}' : '';
    final response = await ApiService.get(
      '/demandes-abonnement/received$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> demandesData = jsonResponse['data'];
      return demandesData
          .map((json) => DemandeAbonnementModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des demandes reçues');
    }
  }

  /// Compter les demandes en attente
  /// GET /demandes-abonnement/pending/count
  /// Réservé aux sociétés
  static Future<int> countDemandesPending() async {
    final response = await ApiService.get('/demandes-abonnement/pending/count');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']['count'];
    } else {
      throw Exception('Erreur de comptage des demandes');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Vérifier si une demande existe déjà pour une société
  /// (Utile pour afficher le bon bouton dans l'UI)
  static Future<DemandeAbonnementModel?> checkDemandeExistante(
    int societeId,
  ) async {
    try {
      final demandes = await getMesDemandesEnvoyees(
        status: DemandeAbonnementStatus.pending,
      );

      return demandes.firstWhere(
        (d) => d.societeId == societeId,
        orElse: () => throw Exception('Aucune demande trouvée'),
      );
    } catch (e) {
      return null; // Aucune demande en attente pour cette société
    }
  }

  /// Récupérer toutes mes demandes (tous statuts)
  static Future<Map<String, List<DemandeAbonnementModel>>>
  getAllDemandesGrouped() async {
    final pending = await getMesDemandesEnvoyees(
      status: DemandeAbonnementStatus.pending,
    );
    final accepted = await getMesDemandesEnvoyees(
      status: DemandeAbonnementStatus.accepted,
    );
    final declined = await getMesDemandesEnvoyees(
      status: DemandeAbonnementStatus.declined,
    );
    final cancelled = await getMesDemandesEnvoyees(
      status: DemandeAbonnementStatus.cancelled,
    );

    return {
      'pending': pending,
      'accepted': accepted,
      'declined': declined,
      'cancelled': cancelled,
    };
  }
}
