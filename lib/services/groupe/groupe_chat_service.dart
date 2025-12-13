import 'dart:convert';
import '../api_service.dart';
import '../messagerie/message_service.dart';

// ============================================================================
// MODÈLES SPÉCIFIQUES AU CHAT DE GROUPE
// ============================================================================

/// Modèle de message de groupe (étend MessageModel avec groupeId)
class GroupeMessageModel {
  final int id;
  final int groupeId;
  final int senderId;
  final String senderType; // 'User' ou 'Societe'
  final String contenu;
  final bool isRead;
  final DateTime createdAt;
  final SenderModel? sender; // Informations complètes de l'expéditeur

  GroupeMessageModel({
    required this.id,
    required this.groupeId,
    required this.senderId,
    required this.senderType,
    required this.contenu,
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  factory GroupeMessageModel.fromJson(Map<String, dynamic> json) {
    return GroupeMessageModel(
      id: json['id'],
      groupeId: json['groupe_id'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      contenu: json['contenu'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'] != null
          ? SenderModel.fromJson(json['sender'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupe_id': groupeId,
      'sender_id': senderId,
      'sender_type': senderType,
      'contenu': contenu,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Vérifier si je suis l'expéditeur du message
  bool isSentByMe(int myId, String myType) {
    return senderId == myId && senderType == myType;
  }

  /// Obtenir le nom de l'expéditeur
  String getSenderName() {
    return sender?.getDisplayName() ?? 'Membre';
  }

  /// Obtenir la couleur de l'avatar basée sur l'ID de l'expéditeur
  int getAvatarColorIndex() {
    return senderId % 10; // Retourne un index entre 0 et 9
  }
}

/// DTO pour envoyer un message dans un groupe
class SendGroupeMessageDto {
  final String contenu;

  SendGroupeMessageDto({
    required this.contenu,
  });

  Map<String, dynamic> toJson() {
    return {'contenu': contenu};
  }
}

/// Statistiques de messages d'un groupe
class GroupeChatStatsModel {
  final int totalMessages;
  final int unreadMessages;
  final int myMessagesCount;

  GroupeChatStatsModel({
    required this.totalMessages,
    required this.unreadMessages,
    required this.myMessagesCount,
  });

  factory GroupeChatStatsModel.fromJson(Map<String, dynamic> json) {
    return GroupeChatStatsModel(
      totalMessages: json['total_messages'] ?? 0,
      unreadMessages: json['unread_messages'] ?? 0,
      myMessagesCount: json['my_messages_count'] ?? 0,
    );
  }
}

// ============================================================================
// SERVICE CHAT DE GROUPE
// ============================================================================

/// Service pour gérer la messagerie des groupes
class GroupeChatService {
  // ==========================================================================
  // ENVOI ET RÉCUPÉRATION DES MESSAGES
  // ==========================================================================

  /// Envoyer un message dans un groupe
  /// POST /groupes/:groupeId/messages
  /// Nécessite authentification et être membre du groupe
  static Future<GroupeMessageModel> sendMessage(
    int groupeId,
    SendGroupeMessageDto dto,
  ) async {
    final response = await ApiService.post(
      '/groupes/$groupeId/messages',
      dto.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeMessageModel.fromJson(jsonResponse['message']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'envoi du message');
    }
  }

  /// Récupérer tous les messages d'un groupe
  /// GET /groupes/:groupeId/messages
  /// Nécessite authentification et être membre du groupe
  /// Retourne les messages triés par date (plus ancien en premier)
  static Future<List<GroupeMessageModel>> getGroupeMessages(
    int groupeId, {
    int? limit,
    int? offset,
  }) async {
    final params = <String>[];
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService.get(
      '/groupes/$groupeId/messages$queryString',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['messages'];
      return messagesData
          .map((json) => GroupeMessageModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des messages du groupe');
    }
  }

  /// Récupérer les messages récents d'un groupe (derniers 50)
  /// Utile pour l'affichage initial du chat
  static Future<List<GroupeMessageModel>> getRecentMessages(
    int groupeId,
  ) async {
    return getGroupeMessages(groupeId, limit: 50);
  }

  /// Récupérer les messages non lus d'un groupe
  /// GET /groupes/:groupeId/messages/unread
  /// Nécessite authentification
  static Future<List<GroupeMessageModel>> getUnreadMessages(
    int groupeId,
  ) async {
    final response = await ApiService.get(
      '/groupes/$groupeId/messages/unread',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['messages'];
      return messagesData
          .map((json) => GroupeMessageModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des messages non lus');
    }
  }

  // ==========================================================================
  // MARQUAGE COMME LU
  // ==========================================================================

  /// Marquer un message comme lu
  /// PUT /groupes/:groupeId/messages/:messageId/read
  /// Nécessite authentification
  static Future<void> markMessageAsRead(int groupeId, int messageId) async {
    final response = await ApiService.put(
      '/groupes/$groupeId/messages/$messageId/read',
      {},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de marquage du message comme lu',
      );
    }
  }

  /// Marquer tous les messages d'un groupe comme lus
  /// PUT /groupes/:groupeId/messages/mark-all-read
  /// Nécessite authentification
  static Future<void> markAllMessagesAsRead(int groupeId) async {
    final response = await ApiService.put(
      '/groupes/$groupeId/messages/mark-all-read',
      {},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de marquage des messages comme lus',
      );
    }
  }

  // ==========================================================================
  // SUPPRESSION
  // ==========================================================================

  /// Supprimer un message (seulement si on est l'auteur ou admin/modérateur)
  /// DELETE /groupes/:groupeId/messages/:messageId
  /// Nécessite authentification
  static Future<void> deleteMessage(int groupeId, int messageId) async {
    final response = await ApiService.delete(
      '/groupes/$groupeId/messages/$messageId',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de suppression du message',
      );
    }
  }

  // ==========================================================================
  // STATISTIQUES
  // ==========================================================================

  /// Récupérer les statistiques du chat du groupe
  /// GET /groupes/:groupeId/messages/stats
  /// Nécessite authentification
  static Future<GroupeChatStatsModel> getGroupeChatStats(int groupeId) async {
    final response = await ApiService.get(
      '/groupes/$groupeId/messages/stats',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeChatStatsModel.fromJson(jsonResponse);
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }

  /// Compter les messages non lus d'un groupe
  static Future<int> countUnreadMessages(int groupeId) async {
    try {
      final stats = await getGroupeChatStats(groupeId);
      return stats.unreadMessages;
    } catch (e) {
      return 0;
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Grouper les messages par date (utile pour l'affichage)
  static Map<DateTime, List<GroupeMessageModel>> groupMessagesByDate(
    List<GroupeMessageModel> messages,
  ) {
    final Map<DateTime, List<GroupeMessageModel>> grouped = {};

    for (final message in messages) {
      // Normaliser la date (supprimer l'heure)
      final date = DateTime(
        message.createdAt.year,
        message.createdAt.month,
        message.createdAt.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }

      grouped[date]!.add(message);
    }

    return grouped;
  }

  /// Formater la date d'un message pour l'affichage
  static String formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Aujourd\'hui';
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else if (now.difference(date).inDays < 7) {
      // Dans la semaine
      const weekDays = [
        'Lundi',
        'Mardi',
        'Mercredi',
        'Jeudi',
        'Vendredi',
        'Samedi',
        'Dimanche'
      ];
      return weekDays[date.weekday - 1];
    } else {
      // Format: 15/03/2025
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Formater l'heure d'un message pour l'affichage
  static String formatMessageTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Obtenir une liste de couleurs pour les avatars
  static List<int> getAvatarColors() {
    return [
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFFF44336, // Red
      0xFFFF9800, // Orange
      0xFF9C27B0, // Purple
      0xFF00BCD4, // Cyan
      0xFFFFEB3B, // Yellow
      0xFFE91E63, // Pink
      0xFF795548, // Brown
      0xFF607D8B, // Blue Grey
    ];
  }
}
