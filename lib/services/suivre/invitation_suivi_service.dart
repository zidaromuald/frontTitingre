import 'dart:convert';
import 'api_service.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Statut d'une invitation de suivi
enum InvitationSuiviStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  cancelled('cancelled');

  final String value;
  const InvitationSuiviStatus(this.value);

  factory InvitationSuiviStatus.fromString(String value) {
    return InvitationSuiviStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvitationSuiviStatus.pending,
    );
  }
}

/// Type d'entité (User ou Societe)
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

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle d'invitation de suivi
class InvitationSuiviModel {
  final int id;
  final int senderId;
  final String senderType; // 'User' ou 'Societe'
  final int receiverId;
  final String receiverType; // 'User' ou 'Societe'
  final InvitationSuiviStatus status;
  final String? message;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations optionnelles (peuvent être incluses selon l'endpoint)
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? receiver;

  InvitationSuiviModel({
    required this.id,
    required this.senderId,
    required this.senderType,
    required this.receiverId,
    required this.receiverType,
    required this.status,
    this.message,
    this.respondedAt,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
    this.receiver,
  });

  factory InvitationSuiviModel.fromJson(Map<String, dynamic> json) {
    return InvitationSuiviModel(
      id: json['id'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      receiverId: json['receiver_id'],
      receiverType: json['receiver_type'],
      status: InvitationSuiviStatus.fromString(json['status'] ?? 'pending'),
      message: json['message'],
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sender: json['sender'],
      receiver: json['receiver'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_type': senderType,
      'receiver_id': receiverId,
      'receiver_type': receiverType,
      'status': status.value,
      if (message != null) 'message': message,
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Méthodes helper
  bool isPending() => status == InvitationSuiviStatus.pending;
  bool isAccepted() => status == InvitationSuiviStatus.accepted;
  bool isDeclined() => status == InvitationSuiviStatus.declined;
  bool isCancelled() => status == InvitationSuiviStatus.cancelled;

  bool isSenderUser() => senderType == 'User';
  bool isSenderSociete() => senderType == 'Societe';
  bool isReceiverUser() => receiverType == 'User';
  bool isReceiverSociete() => receiverType == 'Societe';
}

/// Réponse lors de l'acceptation d'une invitation
class AcceptInvitationResponse {
  final InvitationSuiviModel invitation;
  final int connexionsCreees;

  AcceptInvitationResponse({
    required this.invitation,
    required this.connexionsCreees,
  });

  factory AcceptInvitationResponse.fromJson(Map<String, dynamic> json) {
    return AcceptInvitationResponse(
      invitation: InvitationSuiviModel.fromJson(json['invitation']),
      connexionsCreees: json['connexions_creees'],
    );
  }
}

// ============================================================================
// SERVICE INVITATIONS DE SUIVI
// ============================================================================

/// Service pour gérer les invitations de suivi entre Users et Sociétés
class InvitationSuiviService {
  // ==========================================================================
  // ENVOI D'INVITATIONS
  // ==========================================================================

  /// Envoyer une invitation de suivi (clic "Suivre")
  /// POST /invitations-suivi
  ///
  /// [receiverId] ID de l'entité à suivre
  /// [receiverType] Type: 'User' ou 'Societe'
  /// [message] Message optionnel
  static Future<InvitationSuiviModel> envoyerInvitation({
    required int receiverId,
    required EntityType receiverType,
    String? message,
  }) async {
    final data = {
      'receiver_id': receiverId,
      'receiver_type': receiverType.value,
      if (message != null) 'message': message,
    };

    final response = await ApiService.post('/invitations-suivi', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return InvitationSuiviModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de l\'envoi de l\'invitation',
      );
    }
  }

  /// Annuler une invitation (sender uniquement)
  /// DELETE /invitations-suivi/:id
  static Future<void> annulerInvitation(int invitationId) async {
    final response = await ApiService.delete(
      '/invitations-suivi/$invitationId',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'annulation');
    }
  }

  /// Récupérer mes invitations envoyées
  /// GET /invitations-suivi/sent?status=pending
  static Future<List<InvitationSuiviModel>> getMesInvitationsEnvoyees({
    InvitationSuiviStatus? status,
  }) async {
    final queryString = status != null ? '?status=${status.value}' : '';
    final response = await ApiService.get(
      '/invitations-suivi/sent$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> invitationsData = jsonResponse['data'];
      return invitationsData
          .map((json) => InvitationSuiviModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des invitations envoyées');
    }
  }

  // ==========================================================================
  // RÉCEPTION D'INVITATIONS
  // ==========================================================================

  /// Accepter une invitation de suivi
  /// PUT /invitations-suivi/:id/accept
  /// Crée automatiquement une relation Suivre bidirectionnelle
  static Future<AcceptInvitationResponse> accepterInvitation(
    int invitationId,
  ) async {
    final response = await ApiService.put(
      '/invitations-suivi/$invitationId/accept',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return AcceptInvitationResponse.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'acceptation');
    }
  }

  /// Refuser une invitation de suivi
  /// PUT /invitations-suivi/:id/decline
  static Future<InvitationSuiviModel> refuserInvitation(
    int invitationId,
  ) async {
    final response = await ApiService.put(
      '/invitations-suivi/$invitationId/decline',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return InvitationSuiviModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors du refus');
    }
  }

  /// Récupérer mes invitations reçues
  /// GET /invitations-suivi/received?status=pending
  static Future<List<InvitationSuiviModel>> getMesInvitationsRecues({
    InvitationSuiviStatus? status,
  }) async {
    final queryString = status != null ? '?status=${status.value}' : '';
    final response = await ApiService.get(
      '/invitations-suivi/received$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> invitationsData = jsonResponse['data'];
      return invitationsData
          .map((json) => InvitationSuiviModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des invitations reçues');
    }
  }

  /// Compter mes invitations en attente
  /// GET /invitations-suivi/pending/count
  static Future<int> countInvitationsPending() async {
    final response = await ApiService.get('/invitations-suivi/pending/count');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['data']['count'];
    } else {
      throw Exception('Erreur de comptage des invitations');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Vérifier si une invitation existe déjà pour une entité
  /// (Utile pour afficher le bon bouton dans l'UI)
  static Future<InvitationSuiviModel?> checkInvitationExistante({
    required int receiverId,
    required EntityType receiverType,
  }) async {
    try {
      final invitations = await getMesInvitationsEnvoyees(
        status: InvitationSuiviStatus.pending,
      );

      return invitations.firstWhere(
        (inv) =>
            inv.receiverId == receiverId &&
            inv.receiverType == receiverType.value,
        orElse: () => throw Exception('Aucune invitation trouvée'),
      );
    } catch (e) {
      return null; // Aucune invitation en attente pour cette entité
    }
  }

  /// Récupérer toutes mes invitations envoyées groupées par statut
  static Future<Map<String, List<InvitationSuiviModel>>>
  getAllInvitationsEnvoyeesGrouped() async {
    final pending = await getMesInvitationsEnvoyees(
      status: InvitationSuiviStatus.pending,
    );
    final accepted = await getMesInvitationsEnvoyees(
      status: InvitationSuiviStatus.accepted,
    );
    final declined = await getMesInvitationsEnvoyees(
      status: InvitationSuiviStatus.declined,
    );
    final cancelled = await getMesInvitationsEnvoyees(
      status: InvitationSuiviStatus.cancelled,
    );

    return {
      'pending': pending,
      'accepted': accepted,
      'declined': declined,
      'cancelled': cancelled,
    };
  }

  /// Récupérer toutes mes invitations reçues groupées par statut
  static Future<Map<String, List<InvitationSuiviModel>>>
  getAllInvitationsRecuesGrouped() async {
    final pending = await getMesInvitationsRecues(
      status: InvitationSuiviStatus.pending,
    );
    final accepted = await getMesInvitationsRecues(
      status: InvitationSuiviStatus.accepted,
    );
    final declined = await getMesInvitationsRecues(
      status: InvitationSuiviStatus.declined,
    );

    return {'pending': pending, 'accepted': accepted, 'declined': declined};
  }

  /// Vérifier si je suis en attente d'acceptation
  /// (j'ai envoyé une invitation qui est pending)
  static Future<bool> isWaitingForAcceptance({
    required int receiverId,
    required EntityType receiverType,
  }) async {
    final invitation = await checkInvitationExistante(
      receiverId: receiverId,
      receiverType: receiverType,
    );
    return invitation != null && invitation.isPending();
  }

  /// Vérifier si j'ai une invitation en attente de ma part
  /// (j'ai reçu une invitation pending)
  static Future<InvitationSuiviModel?> getInvitationRecuePending({
    required int senderId,
    required EntityType senderType,
  }) async {
    try {
      final invitations = await getMesInvitationsRecues(
        status: InvitationSuiviStatus.pending,
      );

      return invitations.firstWhere(
        (inv) => inv.senderId == senderId && inv.senderType == senderType.value,
        orElse: () => throw Exception('Aucune invitation trouvée'),
      );
    } catch (e) {
      return null;
    }
  }
}
