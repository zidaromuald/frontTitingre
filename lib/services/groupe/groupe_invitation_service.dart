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
  ///
  /// LOGIQUE BACKEND :
  /// - Si Société + User abonné → Ajout DIRECT (pas d'invitation)
  /// - Sinon → Invitation classique (nécessite acceptation)
  ///
  /// Retourne un Map avec :
  /// - ajoutDirect: bool (true si ajout direct, false si invitation)
  /// - message: String (message du backend)
  /// - invitation: GroupeInvitationModel? (si invitation classique)
  /// - membre: Map? (si ajout direct)
  static Future<Map<String, dynamic>> inviteMembre({
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
      final ajoutDirect = jsonResponse['ajoutDirect'] ?? false;

      if (ajoutDirect) {
        // CAS 1 : Ajout direct (Société + Abonné)
        return {
          'success': true,
          'ajoutDirect': true,
          'message': jsonResponse['message'] ?? 'Membre ajouté directement',
          'membre': jsonResponse['membre'],
        };
      } else {
        // CAS 2 : Invitation classique
        return {
          'success': true,
          'ajoutDirect': false,
          'message': jsonResponse['message'] ?? 'Invitation envoyée',
          'invitation': GroupeInvitationModel.fromJson(jsonResponse['data'] ?? jsonResponse['invitation']),
        };
      }
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
    // Ajouter le paramètre include pour récupérer les informations de l'inviteur
    print('📤 [InvitationService] Appel GET /groupes/invitations/me?include=invitedByUser,groupe');
    final response = await ApiService.get('/groupes/invitations/me?include=invitedByUser,groupe');
    print('📥 [InvitationService] Response status: ${response.statusCode}');
    print('📥 [InvitationService] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> invitationsData = jsonResponse['data'] ?? [];
      print('📥 [InvitationService] Nombre d\'invitations reçues: ${invitationsData.length}');

      // Debug: afficher les données d'invitation pour vérifier la présence de invitedByUser
      if (invitationsData.isNotEmpty) {
        print('📥 [InvitationService] Exemple d\'invitation: ${invitationsData.first}');
      }

      return invitationsData
          .map((json) => GroupeInvitationModel.fromJson(json))
          .toList();
    } else {
      print('❌ [InvitationService] Erreur: ${response.body}');
      throw Exception('Erreur de récupération des invitations');
    }
  }

  /// Récupérer les invitations envoyées par l'utilisateur connecté
  /// GET /groupes/invitations/sent
  /// Nécessite authentification
  static Future<List<GroupeInvitationModel>> getMySentInvitations({
    InvitationStatus? status,
  }) async {
    // Construire les paramètres de requête en incluant les relations
    final params = <String>[];
    if (status != null) params.add('status=${status.value}');
    params.add('include=invitedUser,groupe'); // Inclure l'utilisateur invité et le groupe

    final queryParams = '?${params.join('&')}';
    print('📤 [InvitationService] Appel GET /groupes/invitations/sent$queryParams');
    final response = await ApiService.get('/groupes/invitations/sent$queryParams');
    print('📥 [InvitationService] Response status: ${response.statusCode}');
    print('📥 [InvitationService] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> invitationsData = jsonResponse['data'] ?? jsonResponse['invitations'] ?? [];
      print('📥 [InvitationService] Nombre d\'invitations envoyées: ${invitationsData.length}');

      // Debug: afficher un exemple pour vérifier les données
      if (invitationsData.isNotEmpty) {
        print('📥 [InvitationService] Exemple d\'invitation envoyée: ${invitationsData.first}');
      }

      return invitationsData
          .map((json) => GroupeInvitationModel.fromJson(json))
          .toList();
    } else {
      print('❌ [InvitationService] Erreur: ${response.body}');
      throw Exception('Erreur de récupération des invitations envoyées');
    }
  }

  /// Annuler une invitation envoyée
  /// DELETE /groupes/invitations/:id
  /// Nécessite authentification (et être l'expéditeur)
  static Future<void> cancelInvitation(int invitationId) async {
    final response = await ApiService.delete('/groupes/invitations/$invitationId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Impossible d\'annuler l\'invitation');
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
