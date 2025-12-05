import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle de participant dans une conversation
class ParticipantModel {
  final int id;
  final String type; // 'User' ou 'Societe'
  final String? nom;
  final String? prenom;
  final String? nomSociete;
  final String? email;
  final String? photoUrl;

  ParticipantModel({
    required this.id,
    required this.type,
    this.nom,
    this.prenom,
    this.nomSociete,
    this.email,
    this.photoUrl,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'],
      type: json['type'],
      nom: json['nom'],
      prenom: json['prenom'],
      nomSociete: json['nom_societe'],
      email: json['email'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'nom': nom,
      'prenom': prenom,
      'nom_societe': nomSociete,
      'email': email,
      'photo_url': photoUrl,
    };
  }

  /// Obtenir le nom d'affichage du participant
  String getDisplayName() {
    if (type == 'User') {
      return '${prenom ?? ''} ${nom ?? ''}'.trim();
    } else {
      return nomSociete ?? nom ?? 'Société';
    }
  }
}

/// Modèle de dernier message
class LastMessageModel {
  final int id;
  final String contenu;
  final int senderId;
  final String senderType;
  final bool isRead;
  final DateTime createdAt;

  LastMessageModel({
    required this.id,
    required this.contenu,
    required this.senderId,
    required this.senderType,
    required this.isRead,
    required this.createdAt,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    return LastMessageModel(
      id: json['id'],
      contenu: json['contenu'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenu': contenu,
      'sender_id': senderId,
      'sender_type': senderType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Modèle de conversation
class ConversationModel {
  final int id;
  final List<ParticipantModel> participants;
  final LastMessageModel? lastMessage;
  final int unreadCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> participantsData = json['participants'] ?? [];
    final participants = participantsData
        .map((p) => ParticipantModel.fromJson(p))
        .toList();

    return ConversationModel(
      id: json['id'],
      participants: participants,
      lastMessage: json['last_message'] != null
          ? LastMessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Obtenir l'autre participant (celui qui n'est pas moi)
  ParticipantModel? getOtherParticipant(int myId, String myType) {
    try {
      return participants.firstWhere(
        (p) => !(p.id == myId && p.type == myType),
      );
    } catch (e) {
      return null;
    }
  }

  /// Vérifier si j'ai des messages non lus
  bool hasUnreadMessages() {
    return unreadCount > 0;
  }

  /// Obtenir le titre de la conversation (nom de l'autre participant)
  String getConversationTitle(int myId, String myType) {
    final other = getOtherParticipant(myId, myType);
    return other?.getDisplayName() ?? 'Conversation';
  }
}

/// DTO pour créer ou récupérer une conversation
class CreateConversationDto {
  final int participantId;
  final String participantType; // 'User' ou 'Societe'

  CreateConversationDto({
    required this.participantId,
    required this.participantType,
  });

  Map<String, dynamic> toJson() {
    return {
      'participant_id': participantId,
      'participant_type': participantType,
    };
  }
}

/// Statistiques des conversations
class ConversationStatsModel {
  final int totalConversations;
  final int activeConversations;
  final int archivedConversations;

  ConversationStatsModel({
    required this.totalConversations,
    required this.activeConversations,
    required this.archivedConversations,
  });

  factory ConversationStatsModel.fromJson(Map<String, dynamic> json) {
    return ConversationStatsModel(
      totalConversations: json['total_conversations'] ?? 0,
      activeConversations: json['active_conversations'] ?? 0,
      archivedConversations: json['archived_conversations'] ?? 0,
    );
  }
}

// ============================================================================
// SERVICE CONVERSATIONS
// ============================================================================

/// Service pour gérer les conversations
class ConversationService {
  // ==========================================================================
  // CRÉATION ET RÉCUPÉRATION
  // ==========================================================================

  /// Créer ou récupérer une conversation avec un participant
  /// POST /conversations
  /// Nécessite authentification
  /// Si une conversation existe déjà, la retourne au lieu d'en créer une nouvelle
  static Future<ConversationModel> createOrGetConversation(
    CreateConversationDto dto,
  ) async {
    final response = await ApiService.post('/conversations', dto.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return ConversationModel.fromJson(jsonResponse['conversation']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de création de la conversation',
      );
    }
  }

  /// Récupérer toutes mes conversations actives
  /// GET /conversations
  /// Nécessite authentification
  /// Retourne les conversations non archivées, triées par date de dernier message
  static Future<List<ConversationModel>> getMyConversations() async {
    final response = await ApiService.get('/conversations');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> conversationsData = jsonResponse['conversations'];
      return conversationsData
          .map((json) => ConversationModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des conversations');
    }
  }

  /// Récupérer mes conversations archivées
  /// GET /conversations/archived
  /// Nécessite authentification
  static Future<List<ConversationModel>> getArchivedConversations() async {
    final response = await ApiService.get('/conversations/archived');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> conversationsData = jsonResponse['conversations'];
      return conversationsData
          .map((json) => ConversationModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des conversations archivées');
    }
  }

  /// Récupérer une conversation par son ID
  /// GET /conversations/:id
  /// Nécessite authentification
  static Future<ConversationModel> getConversationById(int id) async {
    final response = await ApiService.get('/conversations/$id');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return ConversationModel.fromJson(jsonResponse['conversation']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de récupération de la conversation',
      );
    }
  }

  // ==========================================================================
  // STATISTIQUES
  // ==========================================================================

  /// Compter mes conversations
  /// GET /conversations/count
  /// Nécessite authentification
  /// Retourne: total, active (non archivées), archived
  static Future<ConversationStatsModel> countConversations() async {
    final response = await ApiService.get('/conversations/count');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return ConversationStatsModel.fromJson(jsonResponse);
    } else {
      throw Exception('Erreur de comptage des conversations');
    }
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  /// Archiver une conversation
  /// PUT /conversations/:id/archive
  /// Nécessite authentification
  static Future<ConversationModel> archiveConversation(int id) async {
    final response = await ApiService.put('/conversations/$id/archive', {});

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return ConversationModel.fromJson(jsonResponse['conversation']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur d\'archivage de la conversation',
      );
    }
  }

  /// Désarchiver une conversation
  /// PUT /conversations/:id/unarchive
  /// Nécessite authentification
  static Future<ConversationModel> unarchiveConversation(int id) async {
    final response = await ApiService.put('/conversations/$id/unarchive', {});

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return ConversationModel.fromJson(jsonResponse['conversation']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de désarchivage de la conversation',
      );
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Toggle archive (archiver si non archivée, désarchiver si archivée)
  static Future<ConversationModel> toggleArchive(int id) async {
    final conversation = await getConversationById(id);

    if (conversation.isArchived) {
      return await unarchiveConversation(id);
    } else {
      return await archiveConversation(id);
    }
  }

  /// Vérifier si une conversation existe avec un participant
  /// Utile avant de créer une nouvelle conversation
  static Future<ConversationModel?> findConversationWith(
    int participantId,
    String participantType,
  ) async {
    try {
      final conversations = await getMyConversations();

      for (final conv in conversations) {
        final hasParticipant = conv.participants.any(
          (p) => p.id == participantId && p.type == participantType,
        );
        if (hasParticipant) {
          return conv;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Compter le total de messages non lus dans toutes les conversations
  static Future<int> getTotalUnreadCount() async {
    try {
      final conversations = await getMyConversations();
      return conversations.fold<int>(
        0,
        (sum, conv) => sum + conv.unreadCount,
      );
    } catch (e) {
      return 0;
    }
  }

  /// Récupérer les conversations avec des messages non lus uniquement
  static Future<List<ConversationModel>> getUnreadConversations() async {
    final conversations = await getMyConversations();
    return conversations.where((conv) => conv.hasUnreadMessages()).toList();
  }

  /// Récupérer les conversations récentes (triées par date)
  /// Limit permet de limiter le nombre de conversations retournées
  static Future<List<ConversationModel>> getRecentConversations({
    int limit = 10,
  }) async {
    final conversations = await getMyConversations();

    // Trier par date de dernier message (plus récent en premier)
    conversations.sort((a, b) {
      final aDate = a.lastMessage?.createdAt ?? a.updatedAt;
      final bDate = b.lastMessage?.createdAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
    });

    // Limiter le nombre de résultats
    return conversations.take(limit).toList();
  }
}
