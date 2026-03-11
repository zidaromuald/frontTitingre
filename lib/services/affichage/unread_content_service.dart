import 'dart:convert';
import '../api_service.dart';
import '../groupe/groupe_service.dart';
import '../messagerie/conversation_service.dart';
import '../AuthUS/auth_base_service.dart';

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
      // IMPORTANT: Convertir en String pour éviter BindingError sur Flutter Web
      nom: (json['nom'] ?? 'Groupe sans nom').toString(),
      description: json['description']?.toString(),
      logo: json['logo']?.toString(),
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
      // IMPORTANT: Convertir en String pour éviter BindingError sur Flutter Web
      nom: (json['nom'] ?? 'Société sans nom').toString(),
      logo: json['logo']?.toString(),
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
  /// [onlyWithUnread] : si true, ne retourne que les groupes avec du contenu non lu
  ///                    si false, retourne tous les groupes (avec les compteurs non lus)
  static Future<List<GroupeWithUnreadContent>> getMyGroupesWithUnreadContent({
    bool onlyWithUnread = false,
  }) async {
    try {
      // Récupérer tous mes groupes
      final mesGroupes = await GroupeAuthService.getMyGroupes();
      print('📊 [UnreadContentService] ${mesGroupes.length} groupes récupérés');

      // Pour chaque groupe, vérifier s'il y a du contenu non lu
      List<GroupeWithUnreadContent> groupesWithUnread = [];

      for (final groupe in mesGroupes) {
        // Récupérer le nombre de messages non lus pour ce groupe
        // (ne pas bloquer si l'endpoint n'existe pas)
        int unreadMessages = 0;
        try {
          unreadMessages = await _getUnreadMessagesCountForGroupe(groupe.id);
        } catch (e) {
          // Ignorer silencieusement - l'endpoint peut ne pas exister
        }

        // Pour l'instant, on ne gère pas les posts de groupe, donc 0
        final unreadPosts = 0;

        // Si onlyWithUnread est true, ne garder que les groupes avec contenu non lu
        // Sinon, ajouter tous les groupes
        if (!onlyWithUnread || unreadMessages > 0 || unreadPosts > 0) {
          groupesWithUnread.add(
            GroupeWithUnreadContent(
              id: groupe.id,
              nom: groupe.nom,
              description: groupe.description,
              logo: groupe.profil?.logo,
              unreadMessagesCount: unreadMessages,
              unreadPostsCount: unreadPosts,
              lastActivityAt: groupe.updatedAt ?? DateTime.now(),
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

      print('📊 [UnreadContentService] ${groupesWithUnread.length} groupes retournés');
      return groupesWithUnread;
    } catch (e) {
      print('❌ Erreur getMyGroupesWithUnreadContent: $e');
      return [];
    }
  }

  /// Récupérer TOUS les groupes dont je suis membre (avec infos de contenu non lu)
  /// Utilisé pour afficher les canaux dans la HomePage
  static Future<List<GroupeWithUnreadContent>> getAllMyGroupes() async {
    return getMyGroupesWithUnreadContent(onlyWithUnread: false);
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
  /// Utilise getMyConversations() pour couvrir aussi les conversations
  /// initiées par la société (quand la société écrit en premier à l'utilisateur)
  static Future<List<SocieteWithUnreadContent>> getMySocietesWithUnreadContent() async {
    try {
      // Récupérer l'identité de l'utilisateur connecté
      final userData = await AuthBaseService.getUserData();
      final userType = await AuthBaseService.getUserType();
      final myId = userData != null ? (userData['id'] as num?)?.toInt() : null;
      final myType = userType == 'user' ? 'User' : 'Societe';

      if (myId == null) return [];

      // Récupérer TOUTES mes conversations (qu'elles soient initiées par moi ou par la société)
      final conversations = await ConversationService.getMyConversations();

      final List<SocieteWithUnreadContent> result = [];
      for (final conv in conversations) {
        // Identifier l'autre participant
        final other = conv.getOtherParticipant(myId, myType);
        if (other == null || other.type != 'Societe') continue;

        // N'afficher que les conversations avec des messages non lus
        if (conv.unreadCount <= 0) continue;

        result.add(SocieteWithUnreadContent(
          id: other.id,
          nom: other.nomSociete ?? other.nom ?? 'Société',
          logo: other.photoUrl,
          unreadMessagesCount: conv.unreadCount,
          lastActivityAt: conv.lastMessage?.createdAt ?? conv.updatedAt,
        ));
      }

      // Trier par activité la plus récente
      result.sort((a, b) {
        if (a.lastActivityAt == null) return 1;
        if (b.lastActivityAt == null) return -1;
        return b.lastActivityAt!.compareTo(a.lastActivityAt!);
      });

      return result;
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
