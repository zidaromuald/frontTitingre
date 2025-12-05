import 'dart:convert';
import '../api_service.dart';
import 'groupe_service.dart'; // Import pour accéder aux modèles

// ============================================================================
// SERVICE INVITATIONS GROUPE
// ============================================================================

/// Service pour gérer les invitations de groupes
/// Correspond au GroupeInvitationController backend
class GroupeInvitationService {
  // ==========================================================================
  // INVITER UN MEMBRE
  // ==========================================================================

  /// Inviter un utilisateur à rejoindre le groupe
  /// POST /groupes/:id/invite
  /// Nécessite authentification
  static Future<GroupeInvitationModel> inviteMembre({
    required int groupeId,
    required int invitedUserId,
    String? message,
  }) async {
    final data = {
      'invited_user_id': invitedUserId,
      if (message != null) 'message': message,
    };

    final response = await ApiService.post('/groupes/$groupeId/invite', data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeInvitationModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'invitation');
    }
  }

  // ==========================================================================
  // CONSULTER MES INVITATIONS
  // ==========================================================================

  /// Récupérer les invitations reçues par l'utilisateur connecté
  /// GET /groupes/invitations/me
  /// Nécessite authentification
  static Future<List<GroupeInvitationModel>> getMyInvitations() async {
    final response = await ApiService.get('/groupes/invitations/me');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> invitationsData = jsonResponse['data'];
      return invitationsData
          .map((json) => GroupeInvitationModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des invitations');
    }
  }

  // ==========================================================================
  // RÉPONDRE AUX INVITATIONS
  // ==========================================================================

  /// Accepter une invitation à rejoindre un groupe
  /// POST /groupes/invitations/:id/accept
  /// Nécessite authentification
  static Future<void> acceptInvitation(int invitationId) async {
    final response = await ApiService.post(
      '/groupes/invitations/$invitationId/accept',
      {},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Impossible d\'accepter l\'invitation',
      );
    }
  }

  /// Refuser une invitation à rejoindre un groupe
  /// POST /groupes/invitations/:id/decline
  /// Nécessite authentification
  static Future<void> declineInvitation(int invitationId) async {
    final response = await ApiService.post(
      '/groupes/invitations/$invitationId/decline',
      {},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Impossible de refuser l\'invitation',
      );
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Filtrer les invitations en attente (non expirées)
  static List<GroupeInvitationModel> filterPendingInvitations(
    List<GroupeInvitationModel> invitations,
  ) {
    return invitations.where((inv) => inv.isPending()).toList();
  }

  /// Filtrer les invitations expirées
  static List<GroupeInvitationModel> filterExpiredInvitations(
    List<GroupeInvitationModel> invitations,
  ) {
    return invitations.where((inv) => inv.isExpired()).toList();
  }

  /// Compter les invitations en attente
  static Future<int> countPendingInvitations() async {
    try {
      final invitations = await getMyInvitations();
      return filterPendingInvitations(invitations).length;
    } catch (e) {
      return 0;
    }
  }
}
