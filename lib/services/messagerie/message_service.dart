import 'dart:convert';
import '../api_service.dart';

// ============================================================================
// MODÈLES
// ============================================================================

/// Modèle de l'expéditeur d'un message
class SenderModel {
  final int id;
  final String type; // 'User' ou 'Societe'
  final String? nom;
  final String? prenom;
  final String? nomSociete;
  final String? photoUrl;

  SenderModel({
    required this.id,
    required this.type,
    this.nom,
    this.prenom,
    this.nomSociete,
    this.photoUrl,
  });

  factory SenderModel.fromJson(Map<String, dynamic> json) {
    return SenderModel(
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

/// Modèle de message
class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderType; // 'User' ou 'Societe'
  final String contenu;
  final bool isRead;
  final int? transactionId; // ID de la transaction associée (optionnel)
  final int? abonnementId; // ID de l'abonnement associé (optionnel)
  final DateTime createdAt;
  final SenderModel? sender; // Informations complètes de l'expéditeur

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.contenu,
    this.isRead = false,
    this.transactionId,
    this.abonnementId,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      senderType: json['sender_type'],
      contenu: json['contenu'],
      isRead: json['is_read'] ?? false,
      transactionId: json['transaction_id'],
      abonnementId: json['abonnement_id'],
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'] != null
          ? SenderModel.fromJson(json['sender'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_type': senderType,
      'contenu': contenu,
      'is_read': isRead,
      'transaction_id': transactionId,
      'abonnement_id': abonnementId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Vérifier si je suis l'expéditeur du message
  bool isSentByMe(int myId, String myType) {
    return senderId == myId && senderType == myType;
  }

  /// Vérifier si le message est lié à une transaction
  bool hasTransaction() {
    return transactionId != null;
  }

  /// Vérifier si le message est lié à un abonnement
  bool hasAbonnement() {
    return abonnementId != null;
  }

  /// Obtenir le nom de l'expéditeur
  String getSenderName() {
    return sender?.getDisplayName() ?? 'Expéditeur inconnu';
  }
}

/// DTO pour envoyer un message
class SendMessageDto {
  final String contenu;
  final int? transactionId; // Optionnel: lier à une transaction
  final int? abonnementId; // Optionnel: lier à un abonnement

  SendMessageDto({
    required this.contenu,
    this.transactionId,
    this.abonnementId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'contenu': contenu,
    };

    if (transactionId != null) {
      data['transaction_id'] = transactionId;
    }

    if (abonnementId != null) {
      data['abonnement_id'] = abonnementId;
    }

    return data;
  }
}

/// Statistiques des messages
class MessageStatsModel {
  final int totalUnreadMessages;

  MessageStatsModel({
    required this.totalUnreadMessages,
  });

  factory MessageStatsModel.fromJson(Map<String, dynamic> json) {
    return MessageStatsModel(
      totalUnreadMessages: json['count'] ?? 0,
    );
  }
}

// ============================================================================
// SERVICE MESSAGES
// ============================================================================

/// Service pour gérer les messages de collaboration
class MessageService {
  // ==========================================================================
  // ENVOI ET RÉCUPÉRATION
  // ==========================================================================

  /// Envoyer un message dans une conversation
  /// POST /messages/conversations/:conversationId
  /// Nécessite authentification
  static Future<MessageModel> sendMessage(
    int conversationId,
    SendMessageDto dto,
  ) async {
    final response = await ApiService.post(
      '/messages/conversations/$conversationId',
      dto.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return MessageModel.fromJson(jsonResponse['message']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur d\'envoi du message');
    }
  }

  /// Récupérer tous les messages d'une conversation
  /// GET /messages/conversations/:conversationId
  /// Nécessite authentification
  /// Retourne les messages triés par date (plus ancien en premier)
  static Future<List<MessageModel>> getMessagesByConversation(
    int conversationId,
  ) async {
    final response = await ApiService.get(
      '/messages/conversations/$conversationId',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['messages'];
      return messagesData.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des messages');
    }
  }

  /// Récupérer les messages non lus d'une conversation
  /// GET /messages/conversations/:conversationId/unread
  /// Nécessite authentification
  static Future<List<MessageModel>> getUnreadMessages(
    int conversationId,
  ) async {
    final response = await ApiService.get(
      '/messages/conversations/$conversationId/unread',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['messages'];
      return messagesData.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Erreur de récupération des messages non lus');
    }
  }

  /// Récupérer les messages liés à une transaction
  /// GET /messages/transactions/:transactionId
  /// Nécessite authentification
  static Future<List<MessageModel>> getMessagesByTransaction(
    int transactionId,
  ) async {
    final response = await ApiService.get(
      '/messages/transactions/$transactionId',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['messages'];
      return messagesData.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Erreur de récupération des messages de la transaction',
      );
    }
  }

  /// Récupérer les messages liés à un abonnement
  /// GET /messages/abonnements/:abonnementId
  /// Nécessite authentification
  static Future<List<MessageModel>> getMessagesByAbonnement(
    int abonnementId,
  ) async {
    final response = await ApiService.get(
      '/messages/abonnements/$abonnementId',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> messagesData = jsonResponse['messages'];
      return messagesData.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Erreur de récupération des messages de l\'abonnement',
      );
    }
  }

  // ==========================================================================
  // MARQUAGE COMME LU
  // ==========================================================================

  /// Marquer un message comme lu
  /// PUT /messages/:id/read
  /// Nécessite authentification
  static Future<MessageModel> markMessageAsRead(int messageId) async {
    final response = await ApiService.put('/messages/$messageId/read', {});

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return MessageModel.fromJson(jsonResponse['message']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur de marquage du message comme lu',
      );
    }
  }

  /// Marquer tous les messages d'une conversation comme lus
  /// PUT /messages/conversations/:conversationId/read-all
  /// Nécessite authentification
  static Future<bool> markAllAsRead(int conversationId) async {
    final response = await ApiService.put(
      '/messages/conversations/$conversationId/read-all',
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
  // STATISTIQUES
  // ==========================================================================

  /// Compter le nombre total de messages non lus
  /// GET /messages/unread/count
  /// Nécessite authentification
  static Future<int> countUnreadMessages() async {
    final response = await ApiService.get('/messages/unread/count');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final stats = MessageStatsModel.fromJson(jsonResponse);
      return stats.totalUnreadMessages;
    } else {
      throw Exception('Erreur de comptage des messages non lus');
    }
  }

  // ==========================================================================
  // MÉTHODES UTILITAIRES
  // ==========================================================================

  /// Envoyer un message simple (sans transaction ni abonnement)
  static Future<MessageModel> sendSimpleMessage(
    int conversationId,
    String contenu,
  ) async {
    return await sendMessage(
      conversationId,
      SendMessageDto(contenu: contenu),
    );
  }

  /// Envoyer un message lié à une transaction
  static Future<MessageModel> sendTransactionMessage(
    int conversationId,
    String contenu,
    int transactionId,
  ) async {
    return await sendMessage(
      conversationId,
      SendMessageDto(
        contenu: contenu,
        transactionId: transactionId,
      ),
    );
  }

  /// Envoyer un message lié à un abonnement
  static Future<MessageModel> sendAbonnementMessage(
    int conversationId,
    String contenu,
    int abonnementId,
  ) async {
    return await sendMessage(
      conversationId,
      SendMessageDto(
        contenu: contenu,
        abonnementId: abonnementId,
      ),
    );
  }

  /// Compter les messages non lus dans une conversation spécifique
  static Future<int> countUnreadInConversation(int conversationId) async {
    try {
      final unreadMessages = await getUnreadMessages(conversationId);
      return unreadMessages.length;
    } catch (e) {
      return 0;
    }
  }

  /// Récupérer les derniers messages d'une conversation (limité)
  static Future<List<MessageModel>> getRecentMessages(
    int conversationId, {
    int limit = 50,
  }) async {
    final messages = await getMessagesByConversation(conversationId);

    // Prendre les N derniers messages
    final startIndex = messages.length > limit ? messages.length - limit : 0;
    return messages.sublist(startIndex);
  }

  /// Vérifier si une conversation a des messages non lus
  static Future<bool> hasUnreadMessages(int conversationId) async {
    try {
      final unreadMessages = await getUnreadMessages(conversationId);
      return unreadMessages.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Grouper les messages par date (utile pour l'affichage)
  static Map<DateTime, List<MessageModel>> groupMessagesByDate(
    List<MessageModel> messages,
  ) {
    final Map<DateTime, List<MessageModel>> grouped = {};

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
}
