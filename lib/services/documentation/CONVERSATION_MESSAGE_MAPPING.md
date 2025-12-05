# 💬 Mapping Conversations & Messages - GestAuth

## 📋 Vue d'Ensemble

Ce document décrit le mapping complet entre:
- **Flutter Service:** [conversation_service.dart](../messagerie/conversation_service.dart) + [message_service.dart](../messagerie/message_service.dart)
- **Backend NestJS:** `ConversationController` + `MessageCollaborationController`

---

## 📊 Résumé

| Service | Endpoints | Modèles | DTOs | Status |
|---------|-----------|---------|------|--------|
| **ConversationService** | 7/7 ✅ | 4 | 1 | ✅ 100% |
| **MessageService** | 8/8 ✅ | 3 | 1 | ✅ 100% |
| **Total** | **15/15** ✅ | **7** | **2** | ✅ **100%** |

---

## 🔄 SERVICE CONVERSATIONS

**Fichier:** `lib/services/messaging/conversation_service.dart`

**Objectif:** Gérer les conversations entre utilisateurs et sociétés

**Lignes de code:** ~450 lignes

---

### 📦 Modèles

#### ConversationModel

```dart
class ConversationModel {
  final int id;
  final List<ParticipantModel> participants;
  final LastMessageModel? lastMessage;
  final int unreadCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Méthodes helper:**
- `getOtherParticipant(myId, myType)`: Récupère l'autre participant
- `hasUnreadMessages()`: Vérifie si des messages non lus
- `getConversationTitle(myId, myType)`: Obtient le titre de la conversation

#### ParticipantModel

```dart
class ParticipantModel {
  final int id;
  final String type; // 'User' ou 'Societe'
  final String? nom;
  final String? prenom;
  final String? nomSociete;
  final String? email;
  final String? photoUrl;
}
```

**Méthode helper:**
- `getDisplayName()`: Retourne le nom à afficher (prenom nom pour User, nom_societe pour Societe)

#### LastMessageModel

```dart
class LastMessageModel {
  final int id;
  final String contenu;
  final int senderId;
  final String senderType;
  final bool isRead;
  final DateTime createdAt;
}
```

#### CreateConversationDto

```dart
class CreateConversationDto {
  final int participantId;
  final String participantType; // 'User' ou 'Societe'
}
```

---

### 🔗 Mapping des Endpoints

| # | Méthode HTTP | Endpoint Backend | Méthode Flutter | Auth | Description |
|---|--------------|------------------|----------------|------|-------------|
| 1 | `POST` | `/conversations` | `createOrGetConversation()` | ✅ | Créer ou récupérer une conversation |
| 2 | `GET` | `/conversations` | `getMyConversations()` | ✅ | Mes conversations actives |
| 3 | `GET` | `/conversations/archived` | `getArchivedConversations()` | ✅ | Mes conversations archivées |
| 4 | `GET` | `/conversations/count` | `countConversations()` | ✅ | Statistiques des conversations |
| 5 | `GET` | `/conversations/:id` | `getConversationById()` | ✅ | Récupérer une conversation |
| 6 | `PUT` | `/conversations/:id/archive` | `archiveConversation()` | ✅ | Archiver une conversation |
| 7 | `PUT` | `/conversations/:id/unarchive` | `unarchiveConversation()` | ✅ | Désarchiver une conversation |

**Total: 7/7 endpoints ✅**

---

### 📝 Détail des Endpoints

#### 1. Créer ou Récupérer une Conversation

**Backend:**
```typescript
@Post()
@UseGuards(JwtAuthGuard)
async createOrGetConversation(
  @Body() createDto: CreateConversationDto,
  @Req() req,
) {
  const user = req.user;
  return this.conversationService.createOrGetConversation(
    user.id,
    user.type,
    createDto.participant_id,
    createDto.participant_type,
  );
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Créer ou récupérer une conversation avec une société
final conversation = await ConversationService.createOrGetConversation(
  CreateConversationDto(
    participantId: 123,
    participantType: 'Societe',
  ),
);

print('Conversation ID: ${conversation.id}');
print('Participants: ${conversation.participants.length}');
```

---

#### 2. Mes Conversations Actives

**Backend:**
```typescript
@Get()
@UseGuards(JwtAuthGuard)
async getMyConversations(@Req() req) {
  const user = req.user;
  return this.conversationService.getMyConversations(user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Afficher toutes mes conversations
final conversations = await ConversationService.getMyConversations();

for (final conv in conversations) {
  final otherParticipant = conv.getOtherParticipant(myId, myType);
  print('${otherParticipant?.getDisplayName()}');
  print('  Messages non lus: ${conv.unreadCount}');

  if (conv.lastMessage != null) {
    print('  Dernier message: ${conv.lastMessage!.contenu}');
  }
}
```

---

#### 3. Mes Conversations Archivées

**Backend:**
```typescript
@Get('archived')
@UseGuards(JwtAuthGuard)
async getArchivedConversations(@Req() req) {
  const user = req.user;
  return this.conversationService.getArchivedConversations(user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Consulter l'archive
final archived = await ConversationService.getArchivedConversations();
print('Conversations archivées: ${archived.length}');
```

---

#### 4. Statistiques des Conversations

**Backend:**
```typescript
@Get('count')
@UseGuards(JwtAuthGuard)
async countConversations(@Req() req) {
  const user = req.user;
  return this.conversationService.countConversations(user.id, user.type);
}
```

**Flutter:**
```dart
static Future<ConversationStatsModel> countConversations() async {
  final response = await ApiService.get('/conversations/count');

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    return ConversationStatsModel.fromJson(jsonResponse);
  } else {
    throw Exception('Erreur de comptage des conversations');
  }
}
```

**Exemple d'utilisation:**
```dart
// Afficher les statistiques
final stats = await ConversationService.countConversations();
print('Total: ${stats.totalConversations}');
print('Actives: ${stats.activeConversations}');
print('Archivées: ${stats.archivedConversations}');
```

---

#### 5. Récupérer une Conversation par ID

**Backend:**
```typescript
@Get(':id')
@UseGuards(JwtAuthGuard)
async getConversationById(@Param('id') id: number, @Req() req) {
  const user = req.user;
  return this.conversationService.getConversationById(id, user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Rafraîchir une conversation
final conversation = await ConversationService.getConversationById(456);
print('Mis à jour: ${conversation.updatedAt}');
```

---

#### 6. Archiver une Conversation

**Backend:**
```typescript
@Put(':id/archive')
@UseGuards(JwtAuthGuard)
async archiveConversation(@Param('id') id: number, @Req() req) {
  const user = req.user;
  return this.conversationService.archiveConversation(id, user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Archiver une vieille conversation
final archivedConv = await ConversationService.archiveConversation(789);
print('Archivée: ${archivedConv.isArchived}'); // true
```

---

#### 7. Désarchiver une Conversation

**Backend:**
```typescript
@Put(':id/unarchive')
@UseGuards(JwtAuthGuard)
async unarchiveConversation(@Param('id') id: number, @Req() req) {
  const user = req.user;
  return this.conversationService.unarchiveConversation(id, user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Restaurer une conversation
final restoredConv = await ConversationService.unarchiveConversation(789);
print('Archivée: ${restoredConv.isArchived}'); // false
```

---

### 🛠️ Méthodes Utilitaires (Bonus)

Ces méthodes n'ont pas d'endpoint backend direct, mais combinent plusieurs appels pour faciliter l'usage:

#### toggleArchive()

```dart
static Future<ConversationModel> toggleArchive(int id) async {
  final conversation = await getConversationById(id);

  if (conversation.isArchived) {
    return await unarchiveConversation(id);
  } else {
    return await archiveConversation(id);
  }
}
```

**Utilisation:**
```dart
// Basculer l'état d'archivage en un clic
final conv = await ConversationService.toggleArchive(conversationId);
```

---

#### findConversationWith()

```dart
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
```

**Utilisation:**
```dart
// Vérifier si une conversation existe avant d'en créer une
final existing = await ConversationService.findConversationWith(123, 'Societe');

if (existing != null) {
  print('Conversation existante trouvée: ${existing.id}');
} else {
  // Créer une nouvelle conversation
  final newConv = await ConversationService.createOrGetConversation(
    CreateConversationDto(participantId: 123, participantType: 'Societe'),
  );
}
```

---

#### getTotalUnreadCount()

```dart
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
```

**Utilisation:**
```dart
// Afficher un badge avec le total des messages non lus
final totalUnread = await ConversationService.getTotalUnreadCount();
print('🔴 $totalUnread messages non lus');
```

---

#### getUnreadConversations()

```dart
static Future<List<ConversationModel>> getUnreadConversations() async {
  final conversations = await getMyConversations();
  return conversations.where((conv) => conv.hasUnreadMessages()).toList();
}
```

**Utilisation:**
```dart
// Filtrer uniquement les conversations avec des messages non lus
final unreadConvs = await ConversationService.getUnreadConversations();
print('${unreadConvs.length} conversations avec messages non lus');
```

---

#### getRecentConversations()

```dart
static Future<List<ConversationModel>> getRecentConversations({
  int limit = 10,
}) async {
  final conversations = await getMyConversations();

  // Trier par date de dernier message
  conversations.sort((a, b) {
    final aDate = a.lastMessage?.createdAt ?? a.updatedAt;
    final bDate = b.lastMessage?.createdAt ?? b.updatedAt;
    return bDate.compareTo(aDate);
  });

  return conversations.take(limit).toList();
}
```

**Utilisation:**
```dart
// Afficher les 5 conversations les plus récentes
final recent = await ConversationService.getRecentConversations(limit: 5);
```

---

## 💬 SERVICE MESSAGES

**Fichier:** `lib/services/messaging/message_service.dart`

**Objectif:** Gérer les messages au sein des conversations

**Lignes de code:** ~480 lignes

---

### 📦 Modèles

#### MessageModel

```dart
class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderType; // 'User' ou 'Societe'
  final String contenu;
  final bool isRead;
  final int? transactionId; // Optionnel: lien avec une transaction
  final int? abonnementId; // Optionnel: lien avec un abonnement
  final DateTime createdAt;
  final SenderModel? sender;
}
```

**Méthodes helper:**
- `isSentByMe(myId, myType)`: Vérifie si je suis l'expéditeur
- `hasTransaction()`: Vérifie si lié à une transaction
- `hasAbonnement()`: Vérifie si lié à un abonnement
- `getSenderName()`: Obtient le nom de l'expéditeur

#### SenderModel

```dart
class SenderModel {
  final int id;
  final String type; // 'User' ou 'Societe'
  final String? nom;
  final String? prenom;
  final String? nomSociete;
  final String? photoUrl;
}
```

**Méthode helper:**
- `getDisplayName()`: Retourne le nom à afficher

#### SendMessageDto

```dart
class SendMessageDto {
  final String contenu;
  final int? transactionId; // Optionnel
  final int? abonnementId; // Optionnel
}
```

---

### 🔗 Mapping des Endpoints

| # | Méthode HTTP | Endpoint Backend | Méthode Flutter | Auth | Description |
|---|--------------|------------------|----------------|------|-------------|
| 1 | `POST` | `/messages/conversations/:conversationId` | `sendMessage()` | ✅ | Envoyer un message |
| 2 | `GET` | `/messages/conversations/:conversationId` | `getMessagesByConversation()` | ✅ | Messages d'une conversation |
| 3 | `PUT` | `/messages/:id/read` | `markMessageAsRead()` | ✅ | Marquer un message comme lu |
| 4 | `PUT` | `/messages/conversations/:conversationId/read-all` | `markAllAsRead()` | ✅ | Marquer tous comme lus |
| 5 | `GET` | `/messages/unread/count` | `countUnreadMessages()` | ✅ | Compter messages non lus |
| 6 | `GET` | `/messages/conversations/:conversationId/unread` | `getUnreadMessages()` | ✅ | Messages non lus d'une conversation |
| 7 | `GET` | `/messages/transactions/:transactionId` | `getMessagesByTransaction()` | ✅ | Messages liés à une transaction |
| 8 | `GET` | `/messages/abonnements/:abonnementId` | `getMessagesByAbonnement()` | ✅ | Messages liés à un abonnement |

**Total: 8/8 endpoints ✅**

---

### 📝 Détail des Endpoints

#### 1. Envoyer un Message

**Backend:**
```typescript
@Post('conversations/:conversationId')
@UseGuards(JwtAuthGuard)
async sendMessage(
  @Param('conversationId') conversationId: number,
  @Body() sendMessageDto: SendMessageDto,
  @Req() req,
) {
  const user = req.user;
  return this.messageService.sendMessage(
    user.id,
    user.type,
    conversationId,
    sendMessageDto,
  );
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Envoyer un message simple
final message = await MessageService.sendMessage(
  conversationId,
  SendMessageDto(contenu: 'Bonjour! Comment allez-vous?'),
);

print('Message envoyé: ${message.id}');

// Envoyer un message lié à une transaction
final transactionMsg = await MessageService.sendMessage(
  conversationId,
  SendMessageDto(
    contenu: 'Voici les détails de la transaction',
    transactionId: 789,
  ),
);

// Envoyer un message lié à un abonnement
final abonnementMsg = await MessageService.sendMessage(
  conversationId,
  SendMessageDto(
    contenu: 'Bienvenue dans votre nouvel abonnement!',
    abonnementId: 456,
  ),
);
```

---

#### 2. Messages d'une Conversation

**Backend:**
```typescript
@Get('conversations/:conversationId')
@UseGuards(JwtAuthGuard)
async getMessagesByConversation(
  @Param('conversationId') conversationId: number,
  @Req() req,
) {
  const user = req.user;
  return this.messageService.getMessagesByConversation(
    conversationId,
    user.id,
    user.type,
  );
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Charger tous les messages d'une conversation
final messages = await MessageService.getMessagesByConversation(conversationId);

// Afficher dans un ListView
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final message = messages[index];
    final isMine = message.isSentByMe(myId, myType);

    return MessageBubble(
      message: message,
      isMe: isMine,
    );
  },
);
```

---

#### 3. Marquer un Message comme Lu

**Backend:**
```typescript
@Put(':id/read')
@UseGuards(JwtAuthGuard)
async markMessageAsRead(@Param('id') id: number, @Req() req) {
  const user = req.user;
  return this.messageService.markMessageAsRead(id, user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Marquer un message comme lu lorsqu'il est visible à l'écran
final updatedMessage = await MessageService.markMessageAsRead(messageId);
print('Message lu: ${updatedMessage.isRead}'); // true
```

---

#### 4. Marquer Tous les Messages comme Lus

**Backend:**
```typescript
@Put('conversations/:conversationId/read-all')
@UseGuards(JwtAuthGuard)
async markAllAsRead(
  @Param('conversationId') conversationId: number,
  @Req() req,
) {
  const user = req.user;
  return this.messageService.markAllAsRead(conversationId, user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Marquer tous les messages d'une conversation comme lus (quand on ouvre la conversation)
await MessageService.markAllAsRead(conversationId);
print('Tous les messages marqués comme lus ✅');
```

---

#### 5. Compter les Messages Non Lus

**Backend:**
```typescript
@Get('unread/count')
@UseGuards(JwtAuthGuard)
async countUnreadMessages(@Req() req) {
  const user = req.user;
  return this.messageService.countUnreadMessages(user.id, user.type);
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Afficher un badge avec le nombre de messages non lus
final unreadCount = await MessageService.countUnreadMessages();

Badge(
  label: Text('$unreadCount'),
  child: Icon(Icons.message),
);
```

---

#### 6. Messages Non Lus d'une Conversation

**Backend:**
```typescript
@Get('conversations/:conversationId/unread')
@UseGuards(JwtAuthGuard)
async getUnreadMessages(
  @Param('conversationId') conversationId: number,
  @Req() req,
) {
  const user = req.user;
  return this.messageService.getUnreadMessages(
    conversationId,
    user.id,
    user.type,
  );
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Afficher uniquement les messages non lus
final unreadMessages = await MessageService.getUnreadMessages(conversationId);
print('${unreadMessages.length} messages non lus dans cette conversation');
```

---

#### 7. Messages Liés à une Transaction

**Backend:**
```typescript
@Get('transactions/:transactionId')
@UseGuards(JwtAuthGuard)
async getMessagesByTransaction(
  @Param('transactionId') transactionId: number,
  @Req() req,
) {
  const user = req.user;
  return this.messageService.getMessagesByTransaction(
    transactionId,
    user.id,
    user.type,
  );
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Afficher l'historique des messages liés à une transaction
final transactionMessages = await MessageService.getMessagesByTransaction(789);

print('Historique de la transaction #789:');
for (final msg in transactionMessages) {
  print('${msg.getSenderName()}: ${msg.contenu}');
}
```

---

#### 8. Messages Liés à un Abonnement

**Backend:**
```typescript
@Get('abonnements/:abonnementId')
@UseGuards(JwtAuthGuard)
async getMessagesByAbonnement(
  @Param('abonnementId') abonnementId: number,
  @Req() req,
) {
  const user = req.user;
  return this.messageService.getMessagesByAbonnement(
    abonnementId,
    user.id,
    user.type,
  );
}
```

**Flutter:**
```dart
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
```

**Exemple d'utilisation:**
```dart
// Afficher l'historique des messages liés à un abonnement
final abonnementMessages = await MessageService.getMessagesByAbonnement(456);

print('Communication avec l\'abonné #456:');
for (final msg in abonnementMessages) {
  print('[${MessageService.formatMessageDate(msg.createdAt)}] ${msg.contenu}');
}
```

---

### 🛠️ Méthodes Utilitaires Messages (Bonus)

#### sendSimpleMessage()

```dart
static Future<MessageModel> sendSimpleMessage(
  int conversationId,
  String contenu,
) async {
  return await sendMessage(
    conversationId,
    SendMessageDto(contenu: contenu),
  );
}
```

**Utilisation:**
```dart
// Raccourci pour envoyer un message simple
await MessageService.sendSimpleMessage(conversationId, 'Bonjour!');
```

---

#### sendTransactionMessage()

```dart
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
```

**Utilisation:**
```dart
// Envoyer un message dans le contexte d'une transaction
await MessageService.sendTransactionMessage(
  conversationId,
  'La transaction a été validée avec succès',
  transactionId,
);
```

---

#### sendAbonnementMessage()

```dart
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
```

**Utilisation:**
```dart
// Envoyer un message dans le contexte d'un abonnement
await MessageService.sendAbonnementMessage(
  conversationId,
  'Votre abonnement a été mis à jour',
  abonnementId,
);
```

---

#### countUnreadInConversation()

```dart
static Future<int> countUnreadInConversation(int conversationId) async {
  try {
    final unreadMessages = await getUnreadMessages(conversationId);
    return unreadMessages.length;
  } catch (e) {
    return 0;
  }
}
```

**Utilisation:**
```dart
// Compter uniquement les non lus d'une conversation spécifique
final unreadCount = await MessageService.countUnreadInConversation(conversationId);
```

---

#### getRecentMessages()

```dart
static Future<List<MessageModel>> getRecentMessages(
  int conversationId, {
  int limit = 50,
}) async {
  final messages = await getMessagesByConversation(conversationId);

  final startIndex = messages.length > limit ? messages.length - limit : 0;
  return messages.sublist(startIndex);
}
```

**Utilisation:**
```dart
// Charger uniquement les 20 derniers messages (optimisation)
final recentMessages = await MessageService.getRecentMessages(
  conversationId,
  limit: 20,
);
```

---

#### hasUnreadMessages()

```dart
static Future<bool> hasUnreadMessages(int conversationId) async {
  try {
    final unreadMessages = await getUnreadMessages(conversationId);
    return unreadMessages.isNotEmpty;
  } catch (e) {
    return false;
  }
}
```

**Utilisation:**
```dart
// Vérifier rapidement s'il y a des non lus
if (await MessageService.hasUnreadMessages(conversationId)) {
  print('⚠️ Messages non lus dans cette conversation');
}
```

---

#### groupMessagesByDate()

```dart
static Map<DateTime, List<MessageModel>> groupMessagesByDate(
  List<MessageModel> messages,
) {
  final Map<DateTime, List<MessageModel>> grouped = {};

  for (final message in messages) {
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
```

**Utilisation:**
```dart
// Grouper les messages par date pour l'affichage
final messages = await MessageService.getMessagesByConversation(conversationId);
final grouped = MessageService.groupMessagesByDate(messages);

// Afficher avec des headers de date
grouped.forEach((date, msgs) {
  print(MessageService.formatMessageDate(date));
  for (final msg in msgs) {
    print('  ${MessageService.formatMessageTime(msg.createdAt)}: ${msg.contenu}');
  }
});
```

---

#### formatMessageDate() et formatMessageTime()

```dart
// Formater la date: "Aujourd'hui", "Hier", "Lundi", "15/03/2025"
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
    const weekDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return weekDays[date.weekday - 1];
  } else {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// Formater l'heure: "14:32"
static String formatMessageTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
```

**Utilisation:**
```dart
final message = messages.first;
print(MessageService.formatMessageDate(message.createdAt)); // "Aujourd'hui"
print(MessageService.formatMessageTime(message.createdAt)); // "14:32"
```

---

## 🎯 Cas d'Usage Complets

### 1. Créer une Conversation et Envoyer un Message

```dart
import 'package:gestauth_clean/services/messaging/conversation_service.dart';
import 'package:gestauth_clean/services/messaging/message_service.dart';

// Étape 1: Créer ou récupérer la conversation
final conversation = await ConversationService.createOrGetConversation(
  CreateConversationDto(
    participantId: 123,
    participantType: 'Societe',
  ),
);

print('Conversation ID: ${conversation.id}');

// Étape 2: Envoyer un message
final message = await MessageService.sendSimpleMessage(
  conversation.id,
  'Bonjour, je suis intéressé par vos services',
);

print('Message envoyé: ${message.id}');
```

---

### 2. Afficher la Liste des Conversations

```dart
// Récupérer toutes les conversations
final conversations = await ConversationService.getMyConversations();

// Afficher dans un ListView
ListView.builder(
  itemCount: conversations.length,
  itemBuilder: (context, index) {
    final conv = conversations[index];
    final otherParticipant = conv.getOtherParticipant(myId, myType);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: otherParticipant?.photoUrl != null
          ? NetworkImage(otherParticipant!.photoUrl!)
          : null,
        child: otherParticipant?.photoUrl == null
          ? Text(otherParticipant?.getDisplayName()[0] ?? '?')
          : null,
      ),
      title: Text(otherParticipant?.getDisplayName() ?? 'Conversation'),
      subtitle: Text(
        conv.lastMessage?.contenu ?? 'Pas de messages',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conv.hasUnreadMessages()
        ? Badge(
            label: Text('${conv.unreadCount}'),
            child: Icon(Icons.message),
          )
        : null,
      onTap: () {
        // Ouvrir la page de conversation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              conversationId: conv.id,
            ),
          ),
        );
      },
    );
  },
);
```

---

### 3. Afficher les Messages d'une Conversation

```dart
class ConversationPage extends StatefulWidget {
  final int conversationId;

  const ConversationPage({required this.conversationId});

  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  List<MessageModel> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => isLoading = true);

    try {
      // Charger les messages
      final loadedMessages = await MessageService.getMessagesByConversation(
        widget.conversationId,
      );

      // Marquer tous comme lus
      await MessageService.markAllAsRead(widget.conversationId);

      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage(String text) async {
    try {
      final message = await MessageService.sendSimpleMessage(
        widget.conversationId,
        text,
      );

      setState(() {
        messages.add(message);
      });
    } catch (e) {
      print('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Grouper les messages par date
    final grouped = MessageService.groupMessagesByDate(messages);

    return Scaffold(
      appBar: AppBar(
        title: Text('Conversation'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: grouped.entries.map((entry) {
                return Column(
                  children: [
                    // Header de date
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        MessageService.formatMessageDate(entry.key),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // Messages du jour
                    ...entry.value.map((msg) => MessageBubble(
                      message: msg,
                      isMe: msg.isSentByMe(myId, myType),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
          MessageInput(onSend: _sendMessage),
        ],
      ),
    );
  }
}
```

---

### 4. Widget MessageBubble

```dart
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.getSenderName(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            SizedBox(height: 4),
            Text(
              message.contenu,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MessageService.formatMessageTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead ? Colors.blue[200] : Colors.white70,
                  ),
                ],
              ],
            ),
            if (message.hasTransaction())
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip(
                  label: Text('Transaction #${message.transactionId}'),
                  backgroundColor: Colors.orange[100],
                ),
              ),
            if (message.hasAbonnement())
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Chip(
                  label: Text('Abonnement #${message.abonnementId}'),
                  backgroundColor: Colors.green[100],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

### 5. Badge de Messages Non Lus Global

```dart
class MessagingBadge extends StatefulWidget {
  @override
  _MessagingBadgeState createState() => _MessagingBadgeState();
}

class _MessagingBadgeState extends State<MessagingBadge> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await MessageService.countUnreadMessages();
      setState(() {
        unreadCount = count;
      });
    } catch (e) {
      print('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: Text('$unreadCount'),
      isLabelVisible: unreadCount > 0,
      child: IconButton(
        icon: Icon(Icons.message),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConversationsListPage(),
            ),
          );
        },
      ),
    );
  }
}
```

---

### 6. Rechercher et Créer une Conversation

```dart
Future<void> startConversationWith(int societeId) async {
  try {
    // Vérifier si une conversation existe déjà
    final existing = await ConversationService.findConversationWith(
      societeId,
      'Societe',
    );

    if (existing != null) {
      // Ouvrir la conversation existante
      print('Conversation existante trouvée: ${existing.id}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationPage(
            conversationId: existing.id,
          ),
        ),
      );
    } else {
      // Créer une nouvelle conversation
      final newConv = await ConversationService.createOrGetConversation(
        CreateConversationDto(
          participantId: societeId,
          participantType: 'Societe',
        ),
      );

      print('Nouvelle conversation créée: ${newConv.id}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationPage(
            conversationId: newConv.id,
          ),
        ),
      );
    }
  } catch (e) {
    print('Erreur: $e');
  }
}
```

---

### 7. Historique Transaction/Abonnement

```dart
// Page pour voir l'historique des échanges liés à une transaction
class TransactionMessagesPage extends StatelessWidget {
  final int transactionId;

  const TransactionMessagesPage({required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages - Transaction #$transactionId'),
      ),
      body: FutureBuilder<List<MessageModel>>(
        future: MessageService.getMessagesByTransaction(transactionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return ListTile(
                title: Text(msg.getSenderName()),
                subtitle: Text(msg.contenu),
                trailing: Text(
                  MessageService.formatMessageTime(msg.createdAt),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 🔐 Sécurité et Authentification

### JWT Automatique

Tous les endpoints utilisent `@UseGuards(JwtAuthGuard)` côté backend. Le token JWT est automatiquement ajouté à chaque requête par `ApiService`.

**Vous n'avez jamais besoin de gérer manuellement le JWT!**

```dart
// Le JWT est géré automatiquement
final conversations = await ConversationService.getMyConversations();
// ↑ Le token est ajouté automatiquement dans le header Authorization
```

### Vérifications Backend

Le backend vérifie automatiquement:
1. **Authentification:** L'utilisateur est-il connecté?
2. **Type d'utilisateur:** Est-ce un User ou une Societe?
3. **Permissions:** A-t-il accès à cette conversation/message?

---

## ✅ Checklist Complète

### Service Conversations
- [x] Créer ou récupérer conversation ✅
- [x] Mes conversations actives ✅
- [x] Mes conversations archivées ✅
- [x] Statistiques conversations ✅
- [x] Récupérer par ID ✅
- [x] Archiver ✅
- [x] Désarchiver ✅

**Total: 7/7 endpoints ✅**

### Service Messages
- [x] Envoyer un message ✅
- [x] Messages d'une conversation ✅
- [x] Marquer comme lu ✅
- [x] Marquer tous comme lus ✅
- [x] Compter messages non lus ✅
- [x] Messages non lus d'une conversation ✅
- [x] Messages par transaction ✅
- [x] Messages par abonnement ✅

**Total: 8/8 endpoints ✅**

### Documentation
- [x] Mapping complet conversations ✅
- [x] Mapping complet messages ✅
- [x] 7 cas d'usage détaillés ✅
- [x] Widgets d'exemple ✅
- [x] Méthodes utilitaires bonus ✅

---

## 🎉 Conclusion

Les services de messagerie sont **100% fonctionnels** et prêts à l'emploi:

- ✅ **15 endpoints** implémentés (7 conversations + 8 messages)
- ✅ **7 modèles/DTOs** complets
- ✅ **Méthodes utilitaires** pratiques
- ✅ **Formatage de dates** intelligent
- ✅ **Documentation exhaustive**
- ✅ **Exemples de widgets** complets

**Le système de messagerie est prêt pour la production! 🚀**

---

**Lignes de code:** ~930 lignes (Conversations: 450, Messages: 480)
**Endpoints:** 15/15 ✅ (Conversations: 7, Messages: 8)
**Conformité:** 100% ✅
**Date:** 2025-12-01
