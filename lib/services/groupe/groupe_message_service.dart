import 'dart:convert';
import 'package:gestauth_clean/services/api_service.dart';

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle de l'expéditeur d'un message de groupe
class GroupeSenderModel {
  final int id;
  final String type; // 'User' ou 'Societe'
  final String? nom;
  final String? prenom;
  final String? nomSociete;
  final String? photoUrl;

  GroupeSenderModel({
    required this.id,
    required this.type,
    this.nom,
    this.prenom,
    this.nomSociete,
    this.photoUrl,
  });

  factory GroupeSenderModel.fromJson(Map<String, dynamic> json) {
    return GroupeSenderModel(
      id: json['id'],
      type: json['type'],
      nom: json['nom'],
      prenom: json['prenom'],
      nomSociete: json['nom_societe'],
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
      'photo_url': photoUrl,
    };
  }

  /// Obtenir le nom d'affichage de l'expéditeur
  String getDisplayName() {
    if (type == 'User') {
      return '${prenom ?? ''} ${nom ?? ''}'.trim();
    } else {
      return nomSociete ?? nom ?? 'Société';
    }
  }
}

/// Modèle de message de groupe
class GroupeMessageModel {
  final int id;
  final int groupeId;
  final int senderId;
  final String senderType; // 'User' ou 'Societe'
  final String contenu;
  final bool isRead;
  final bool isPinned;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GroupeSenderModel? sender; // Informations complètes de l'expéditeur

  GroupeMessageModel({
    required this.id,
    required this.groupeId,
    required this.senderId,
    required this.senderType,
    required this.contenu,
    this.isRead = false,
    this.isPinned = false,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
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
      isPinned: json['is_pinned'] ?? false,
      isEdited: json['is_edited'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sender: json['sender'] != null
          ? GroupeSenderModel.fromJson(json['sender'])
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
      'is_pinned': isPinned,
      'is_edited': isEdited,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Vérifier si je suis l'expéditeur du message
  bool isSentByMe(int myId, String myType) {
    return senderId == myId && senderType == myType;
  }

  /// Obtenir le nom de l'expéditeur
  String getSenderName() {
    return sender?.getDisplayName() ?? 'Expéditeur inconnu';
  }
}

/// DTO pour envoyer un message dans un groupe
class SendGroupMessageDto {
  final String contenu;

  SendGroupMessageDto({required this.contenu});

  Map<String, dynamic> toJson() {
    return {'contenu': contenu};
  }
}

/// DTO pour modifier un message de groupe
class UpdateGroupMessageDto {
  final String contenu;

  UpdateGroupMessageDto({required this.contenu});

  Map<String, dynamic> toJson() {
    return {'contenu': contenu};
  }
}

/// Statistiques des messages d'un groupe
class GroupeMessageStatsModel {
  final int totalMessages;
  final int unreadMessages;
  final int pinnedMessages;

  GroupeMessageStatsModel({
    required this.totalMessages,
    required this.unreadMessages,
    required this.pinnedMessages,
  });

  factory GroupeMessageStatsModel.fromJson(Map<String, dynamic> json) {
    return GroupeMessageStatsModel(
      totalMessages: json['total_messages'] ?? 0,
      unreadMessages: json['unread_messages'] ?? 0,
      pinnedMessages: json['pinned_messages'] ?? 0,
    );
  }
}

// ============================================================================
// SERVICE MESSAGES GROUPE
// ============================================================================

/// Service pour gérer les messages dans les groupes
class GroupeMessageService {
  // ==========================================================================
  // ENVOI ET RÉCUPÉRATION
  // ==========================================================================

  /// Envoyer un message dans un groupe
  /// POST /groupes/:groupeId/messages
  /// Nécessite authentification
  static Future<GroupeMessageModel> sendMessage(
    int groupeId,
    SendGroupMessageDto dto,
  ) async {
    final response = await ApiService.post(
      '/groupes/$groupeId/messages',
      dto.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeMessageModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'envoi du message');
    }
  }

  /// Récupérer tous les messages d'un groupe
  /// GET /groupes/:groupeId/messages
  /// Nécessite authentification
  /// Retourne les messages triés par date (plus ancien en premier)
  static Future<List<GroupeMessageModel>> getMessagesByGroupe(
    int groupeId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await ApiService.get(
      '/groupes/$groupeId/messages?limit=$limit&offset=$offset',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['data'];
      return messagesData
          .map((json) => GroupeMessageModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des messages');
    }
  }

  /// Récupérer les messages non lus d'un groupe
  /// GET /groupes/:groupeId/messages/unread
  /// Nécessite authentification
  static Future<List<GroupeMessageModel>> getUnreadMessages(
    int groupeId,
  ) async {
    final response = await ApiService.get('/groupes/$groupeId/messages/unread');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['data'];
      return messagesData
          .map((json) => GroupeMessageModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des messages non lus');
    }
  }

  /// Récupérer les statistiques de messages d'un groupe
  /// GET /groupes/:groupeId/messages/stats
  /// Nécessite authentification
  static Future<GroupeMessageStatsModel> getMessagesStats(int groupeId) async {
    final response = await ApiService.get('/groupes/$groupeId/messages/stats');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeMessageStatsModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Erreur de récupération des statistiques');
    }
  }

  // ==========================================================================
  // MARQUAGE COMME LU
  // ==========================================================================

  /// Marquer un message comme lu
  /// PUT /groupes/:groupeId/messages/:id/read
  /// Nécessite authentification
  static Future<GroupeMessageModel> markMessageAsRead(
    int groupeId,
    int messageId,
  ) async {
    final response = await ApiService.put(
      '/groupes/$groupeId/messages/$messageId/read',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeMessageModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de marquage du message comme lu',
      );
    }
  }

  /// Marquer tous les messages d'un groupe comme lus
  /// PUT /groupes/:groupeId/messages/mark-all-read
  /// Nécessite authentification
  static Future<bool> markAllMessagesAsRead(int groupeId) async {
    final response = await ApiService.put(
      '/groupes/$groupeId/messages/mark-all-read',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['success'] ?? true;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de marquage des messages comme lus',
      );
    }
  }

  // ==========================================================================
  // MODIFICATION ET SUPPRESSION
  // ==========================================================================

  /// Modifier un message (uniquement si je suis l'expéditeur)
  /// PUT /groupes/:groupeId/messages/:id
  /// Nécessite authentification
  static Future<GroupeMessageModel> updateMessage(
    int groupeId,
    int messageId,
    UpdateGroupMessageDto dto,
  ) async {
    final response = await ApiService.put(
      '/groupes/$groupeId/messages/$messageId',
      dto.toJson(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeMessageModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de modification du message');
    }
  }

  /// Supprimer un message (uniquement si je suis l'expéditeur ou admin)
  /// DELETE /groupes/:groupeId/messages/:id
  /// Nécessite authentification
  static Future<void> deleteMessage(int groupeId, int messageId) async {
    final response = await ApiService.delete(
      '/groupes/$groupeId/messages/$messageId',
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur de suppression du message');
    }
  }

  /// Récupérer les messages épinglés d'un groupe
  /// GET /groupes/:groupeId/messages/pinned
  /// Nécessite authentification
  static Future<List<GroupeMessageModel>> getPinnedMessages(
    int groupeId,
  ) async {
    final response = await ApiService.get('/groupes/$groupeId/messages/pinned');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['data'];
      return messagesData
          .map((json) => GroupeMessageModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur de récupération des messages épinglés');
    }
  }

  // ==========================================================================
  // ÉPINGLAGE (Admin/Modérateur uniquement)
  // ==========================================================================

  /// Épingler/Désépingler un message (admin/modérateur uniquement)
  /// PUT /groupes/:groupeId/messages/:id/pin
  /// Nécessite authentification + rôle admin/modérateur
  static Future<GroupeMessageModel> pinMessage(
    int groupeId,
    int messageId,
  ) async {
    final response = await ApiService.put(
      '/groupes/$groupeId/messages/$messageId/pin',
      {},
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GroupeMessageModel.fromJson(jsonResponse['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'épinglage du message');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Envoyer un message simple dans un groupe
  static Future<GroupeMessageModel> sendSimpleMessage(
    int groupeId,
    String contenu,
  ) async {
    return await sendMessage(groupeId, SendGroupMessageDto(contenu: contenu));
  }

  /// Compter les messages non lus dans un groupe
  static Future<int> countUnreadInGroupe(int groupeId) async {
    try {
      final unreadMessages = await getUnreadMessages(groupeId);
      return unreadMessages.length;
    } catch (e) {
      return 0;
    }
  }

  /// Récupérer les derniers messages d'un groupe (limité)
  static Future<List<GroupeMessageModel>> getRecentMessages(
    int groupeId, {
    int limit = 50,
  }) async {
    return await getMessagesByGroupe(groupeId, limit: limit, offset: 0);
  }

  /// Vérifier si un groupe a des messages non lus
  static Future<bool> hasUnreadMessages(int groupeId) async {
    try {
      final unreadMessages = await getUnreadMessages(groupeId);
      return unreadMessages.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

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
        'Dimanche',
      ];
      return weekDays[date.weekday - 1];
    } else {
      // Format: 15/12/2025
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Formater l'heure d'un message pour l'affichage
  static String formatMessageTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
