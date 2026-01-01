import 'dart:convert';
import '../api_service.dart';
import '../groupe/groupe_service.dart';

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle représentant un groupe avec du contenu non lu
class GroupeWithUnreadContent {
  final int id;
  final String nom;
  final String? description;
  final String? logo;
  final int unreadMessagesCount;
  final int unreadPostsCount;
  final DateTime? lastActivityAt;

  GroupeWithUnreadContent({
    required this.id,
    required this.nom,
    this.description,
    this.logo,
    required this.unreadMessagesCount,
    required this.unreadPostsCount,
    this.lastActivityAt,
  });

  factory GroupeWithUnreadContent.fromJson(Map<String, dynamic> json) {
    return GroupeWithUnreadContent(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      logo: json['logo'],
      unreadMessagesCount: json['unread_messages_count'] ?? 0,
      unreadPostsCount: json['unread_posts_count'] ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'])
          : null,
    );
  }

  /// Total de contenus non lus (messages + posts)
  int get totalUnread => unreadMessagesCount + unreadPostsCount;

  /// Vérifier si le groupe a du contenu non lu
  bool get hasUnreadContent => totalUnread > 0;
}

/// Modèle représentant une société avec du contenu non lu
class SocieteWithUnreadContent {
  final int id;
  final String nom;
  final String? logo;
  final int unreadMessagesCount;
  final DateTime? lastActivityAt;

  SocieteWithUnreadContent({
    required this.id,
    required this.nom,
    this.logo,
    required this.unreadMessagesCount,
    this.lastActivityAt,
  });

  factory SocieteWithUnreadContent.fromJson(Map<String, dynamic> json) {
    return SocieteWithUnreadContent(
      id: json['id'],
      nom: json['nom'],
      logo: json['logo'],
      unreadMessagesCount: json['unread_messages_count'] ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'])
          : null,
    );
  }

  /// Vérifier si la société a du contenu non lu
  bool get hasUnreadContent => unreadMessagesCount > 0;
}

// ============================================================================
// SERVICE CONTENU NON LU
// ============================================================================

/// Service pour récupérer les groupes et sociétés avec du contenu non lu
class UnreadContentService {
  // ==========================================================================
  // GROUPES AVEC CONTENU NON LU
  // ==========================================================================

  /// Récupérer les groupes dont je suis membre avec du contenu non lu
  /// GET /groupes/with-unread-content
  static Future<List<GroupeWithUnreadContent>> getMyGroupesWithUnreadContent() async {
    try {
      // Récupérer tous mes groupes
      final mesGroupes = await GroupeAuthService.getMyGroupes();

      // Pour chaque groupe, vérifier s'il y a du contenu non lu
      List<GroupeWithUnreadContent> groupesWithUnread = [];

      for (final groupe in mesGroupes) {
        // Récupérer le nombre de messages non lus pour ce groupe
        final unreadMessages = await _getUnreadMessagesCountForGroupe(groupe.id);

        // Pour l'instant, on ne gère pas les posts de groupe, donc 0
        final unreadPosts = 0;

        // Si le groupe a du contenu non lu, l'ajouter à la liste
        if (unreadMessages > 0 || unreadPosts > 0) {
          groupesWithUnread.add(
            GroupeWithUnreadContent(
              id: groupe.id,
              nom: groupe.nom,
              description: groupe.description,
              logo: groupe.profil?.logo,
              unreadMessagesCount: unreadMessages,
              unreadPostsCount: unreadPosts,
              lastActivityAt: DateTime.now(), // TODO: Récupérer la vraie date
            ),
          );
        }
      }

      // Trier par activité la plus récente
      groupesWithUnread.sort((a, b) {
        if (a.lastActivityAt == null) return 1;
        if (b.lastActivityAt == null) return -1;
        return b.lastActivityAt!.compareTo(a.lastActivityAt!);
      });

      return groupesWithUnread;
    } catch (e) {
      print('❌ Erreur getMyGroupesWithUnreadContent: $e');
      return [];
    }
  }

  /// Récupérer le nombre de messages non lus pour un groupe spécifique
  static Future<int> _getUnreadMessagesCountForGroupe(int groupeId) async {
    try {
      final response = await ApiService.get(
        '/groupes/$groupeId/messages/unread',
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> messages = jsonResponse['data'] ?? jsonResponse['messages'] ?? [];
        return messages.length;
      } else {
        return 0;
      }
    } catch (e) {
      print(' Erreur _getUnreadMessagesCountForGroupe: $e');
      return 0;
    }
  }

  // ==========================================================================
  // SOCIÉTÉS AVEC CONTENU NON LU
  // ==========================================================================

  /// Récupérer les sociétés avec lesquelles j'ai des conversations non lues
  /// GET /conversations/with-unread-messages
  static Future<List<SocieteWithUnreadContent>> getMySocietesWithUnreadContent() async {
    try {
      final response = await ApiService.get('/conversations/with-unread-messages');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> societesData = jsonResponse['data'] ?? jsonResponse['conversations'] ?? [];

        return societesData
            .map((json) => SocieteWithUnreadContent.fromJson(json))
            .where((societe) => societe.hasUnreadContent)
            .toList();
      } else {
        print('❌ Erreur getMySocietesWithUnreadContent: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur getMySocietesWithUnreadContent: $e');
      return [];
    }
  }

  /// Version alternative : Récupérer depuis mes abonnements
  static Future<List<SocieteWithUnreadContent>> getMySocietesWithUnreadContentFromAbonnements() async {
    try {
      // TODO: Implémenter la logique pour récupérer les sociétés depuis les abonnements
      // avec le nombre de messages non lus

      // Pour l'instant, retourner une liste vide
      return [];
    } catch (e) {
      print('❌ Erreur getMySocietesWithUnreadContentFromAbonnements: $e');
      return [];
    }
  }

  // ==========================================================================
  // STATISTIQUES GLOBALES
  // ==========================================================================

  /// Récupérer le nombre total de contenus non lus (groupes + sociétés)
  static Future<int> getTotalUnreadCount() async {
    try {
      final groupes = await getMyGroupesWithUnreadContent();
      final societes = await getMySocietesWithUnreadContent();

      int totalGroupesUnread = groupes.fold(0, (sum, g) => sum + g.totalUnread);
      int totalSocietesUnread = societes.fold(0, (sum, s) => sum + s.unreadMessagesCount);

      return totalGroupesUnread + totalSocietesUnread;
    } catch (e) {
      print('❌ Erreur getTotalUnreadCount: $e');
      return 0;
    }
  }

  /// Récupérer le nombre de groupes avec du contenu non lu
  static Future<int> getGroupesWithUnreadCount() async {
    try {
      final groupes = await getMyGroupesWithUnreadContent();
      return groupes.length;
    } catch (e) {
      return 0;
    }
  }

  /// Récupérer le nombre de sociétés avec du contenu non lu
  static Future<int> getSocietesWithUnreadCount() async {
    try {
      final societes = await getMySocietesWithUnreadContent();
      return societes.length;
    } catch (e) {
      return 0;
    }
  }
}
