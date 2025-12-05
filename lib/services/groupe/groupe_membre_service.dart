import 'dart:convert';
import '../api_service.dart';
import 'groupe_service.dart'; // Import pour accéder aux modèles

// ============================================================================
// SERVICE MEMBRES GROUPE
// ============================================================================

/// Service pour gérer les membres des groupes
/// Correspond au GroupeMembreController backend
class GroupeMembreService {
  // ==========================================================================
  // CONSULTER LES MEMBRES
  // ==========================================================================

  /// Récupérer la liste des membres d'un groupe
  /// GET /groupes/:groupeId/membres
  /// Nécessite authentification
  static Future<List<Map<String, dynamic>>> getMembres(
    int groupeId, {
    int? limit,
    int? offset,
  }) async {
    final params = <String>[];
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get(
      '/groupes/$groupeId/membres$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonResponse['data']);
    } else {
      throw Exception('Erreur de récupération des membres');
    }
  }

  // ==========================================================================
  // REJOINDRE UN GROUPE
  // ==========================================================================

  /// Rejoindre un groupe public (sans invitation)
  /// POST /groupes/:groupeId/membres/join
  /// Nécessite authentification
  static Future<void> joinGroupe(int groupeId) async {
    final response = await ApiService.post(
      '/groupes/$groupeId/membres/join',
      {},
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Impossible de rejoindre le groupe');
    }
  }

  // ==========================================================================
  // GESTION DES RÔLES
  // ==========================================================================

  /// Mettre à jour le rôle d'un membre (admin uniquement)
  /// PUT /groupes/:groupeId/membres/:userId/role
  /// Nécessite authentification + être admin
  static Future<void> updateMembreRole(
    int groupeId,
    int userId,
    MembreRole role,
  ) async {
    final data = {'role': role.value};

    final response = await ApiService.put(
      '/groupes/$groupeId/membres/$userId/role',
      data,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Impossible de modifier le rôle');
    }
  }

  /// Promouvoir un membre en modérateur
  static Future<void> promoteToModerator(
    int groupeId,
    int userId,
  ) async {
    await updateMembreRole(groupeId, userId, MembreRole.moderateur);
  }

  /// Promouvoir un membre en admin
  static Future<void> promoteToAdmin(
    int groupeId,
    int userId,
  ) async {
    await updateMembreRole(groupeId, userId, MembreRole.admin);
  }

  /// Rétrograder un membre
  static Future<void> demoteToMembre(
    int groupeId,
    int userId,
  ) async {
    await updateMembreRole(groupeId, userId, MembreRole.membre);
  }

  // ==========================================================================
  // EXPULSION ET MODÉRATION
  // ==========================================================================

  /// Expulser un membre du groupe (admin uniquement)
  /// DELETE /groupes/:groupeId/membres/:userId
  /// Nécessite authentification + être admin
  static Future<void> removeMembre(int groupeId, int userId) async {
    final response = await ApiService.delete(
      '/groupes/$groupeId/membres/$userId',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Impossible de retirer le membre');
    }
  }

  /// Suspendre un membre (admin uniquement)
  /// POST /groupes/:groupeId/membres/:userId/suspend
  /// Nécessite authentification + être admin
  static Future<void> suspendMembre(int groupeId, int userId) async {
    final response = await ApiService.post(
      '/groupes/$groupeId/membres/$userId/suspend',
      {},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Impossible de suspendre le membre');
    }
  }

  /// Bannir un membre définitivement (admin uniquement)
  /// POST /groupes/:groupeId/membres/:userId/ban
  /// Nécessite authentification + être admin
  static Future<void> banMembre(int groupeId, int userId) async {
    final response = await ApiService.post(
      '/groupes/$groupeId/membres/$userId/ban',
      {},
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Impossible de bannir le membre');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Compter le nombre de membres
  static Future<int> countMembres(int groupeId) async {
    try {
      final membres = await getMembres(groupeId);
      return membres.length;
    } catch (e) {
      return 0;
    }
  }

  /// Filtrer les membres par rôle
  static List<Map<String, dynamic>> filterByRole(
    List<Map<String, dynamic>> membres,
    MembreRole role,
  ) {
    return membres.where((m) => m['role'] == role.value).toList();
  }

  /// Récupérer uniquement les admins
  static Future<List<Map<String, dynamic>>> getAdmins(int groupeId) async {
    final membres = await getMembres(groupeId);
    return filterByRole(membres, MembreRole.admin);
  }

  /// Récupérer uniquement les modérateurs
  static Future<List<Map<String, dynamic>>> getModerators(int groupeId) async {
    final membres = await getMembres(groupeId);
    return filterByRole(membres, MembreRole.moderateur);
  }

  /// Vérifier si un utilisateur est membre
  static Future<bool> isUserMembre(
    int groupeId,
    int userId,
    List<Map<String, dynamic>> membres,
  ) async {
    return membres.any((m) => m['user_id'] == userId);
  }

  /// Vérifier si un utilisateur est admin
  static bool isUserAdmin(
    int userId,
    List<Map<String, dynamic>> membres,
  ) {
    final user = membres.firstWhere(
      (m) => m['user_id'] == userId,
      orElse: () => {},
    );
    return user.isNotEmpty && user['role'] == MembreRole.admin.value;
  }
}
