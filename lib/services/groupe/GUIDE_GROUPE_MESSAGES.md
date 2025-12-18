# 💬 Guide - Messages de Groupe

Ce guide explique comment utiliser le service **GroupeMessageService** pour gérer les messages dans les groupes.

---

## 🎯 Vue d'Ensemble

Le service `GroupeMessageService` permet de :
- ✅ Envoyer des messages dans un groupe
- ✅ Récupérer les messages d'un groupe
- ✅ Marquer les messages comme lus
- ✅ Modifier/Supprimer ses propres messages
- ✅ Épingler des messages (admin/modérateur uniquement)
- ✅ Consulter les statistiques de messages

---

## 📊 Architecture Backend

```
┌─────────────────────────────────────────────────────────────┐
│                    GROUPE                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  id: 1                                                │  │
│  │  nom: "Groupe Café Bio"                               │  │
│  │  type: "public"                                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ 1 Groupe → N Messages
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   MESSAGE 1  │  │   MESSAGE 2  │  │   MESSAGE 3  │
│              │  │              │  │              │
│ groupe_id: 1 │  │ groupe_id: 1 │  │ groupe_id: 1 │
│ contenu: "Hi"│  │ contenu: "?" │  │ is_pinned: ✅│
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 🔑 Routes API Backend

| Méthode | Route | Description | Permissions |
|---------|-------|-------------|-------------|
| POST | `/groupes/:groupeId/messages` | Envoyer un message | Membre du groupe |
| GET | `/groupes/:groupeId/messages` | Récupérer tous les messages | Membre du groupe |
| GET | `/groupes/:groupeId/messages/unread` | Récupérer messages non lus | Membre du groupe |
| GET | `/groupes/:groupeId/messages/pinned` | Récupérer messages épinglés | Membre du groupe |
| GET | `/groupes/:groupeId/messages/stats` | Statistiques de messages | Membre du groupe |
| PUT | `/groupes/:groupeId/messages/:id/read` | Marquer comme lu | Membre du groupe |
| PUT | `/groupes/:groupeId/messages/mark-all-read` | Marquer tout comme lu | Membre du groupe |
| PUT | `/groupes/:groupeId/messages/:id` | Modifier un message | Expéditeur uniquement |
| DELETE | `/groupes/:groupeId/messages/:id` | Supprimer un message | Expéditeur ou Admin |
| PUT | `/groupes/:groupeId/messages/:id/pin` | Épingler/Désépingler | Admin/Modérateur |

---

## 💻 Exemples d'Utilisation

### **1. Envoyer un Message**

```dart
import 'package:gestauth_clean/services/groupe/groupe_message_service.dart';

Future<void> envoyerMessage(int groupeId, String contenu) async {
  try {
    final message = await GroupeMessageService.sendSimpleMessage(
      groupeId,
      contenu,
    );

    print('✅ Message envoyé: ${message.id}');
    print('Contenu: ${message.contenu}');
    print('Date: ${message.createdAt}');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// EXEMPLE
void main() async {
  await envoyerMessage(1, 'Bonjour tout le monde !');
}
```

---

### **2. Charger les Messages d'un Groupe**

```dart
Future<void> chargerMessagesGroupe(int groupeId) async {
  try {
    // Récupérer les 50 derniers messages
    final messages = await GroupeMessageService.getRecentMessages(
      groupeId,
      limit: 50,
    );

    print('✅ ${messages.length} messages chargés');

    for (final message in messages) {
      final senderName = message.getSenderName();
      final time = GroupeMessageService.formatMessageTime(message.createdAt);

      print('[$time] $senderName: ${message.contenu}');

      if (message.isPinned) {
        print('  📌 Message épinglé');
      }

      if (message.isEdited) {
        print('  ✏️ Modifié');
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// EXEMPLE
void main() async {
  await chargerMessagesGroupe(1);
}
```

---

### **3. Récupérer les Messages Non Lus**

```dart
Future<void> verifierMessagesNonLus(int groupeId) async {
  try {
    final unreadMessages = await GroupeMessageService.getUnreadMessages(
      groupeId,
    );

    print('✅ Vous avez ${unreadMessages.length} messages non lus');

    for (final message in unreadMessages) {
      print('  • ${message.getSenderName()}: ${message.contenu}');
    }

    // Marquer tous comme lus
    if (unreadMessages.isNotEmpty) {
      await GroupeMessageService.markAllMessagesAsRead(groupeId);
      print('✅ Tous les messages ont été marqués comme lus');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// EXEMPLE
void main() async {
  await verifierMessagesNonLus(1);
}
```

---

### **4. Modifier un Message**

```dart
Future<void> modifierMessage(
  int groupeId,
  int messageId,
  String nouveauContenu,
) async {
  try {
    final updatedMessage = await GroupeMessageService.updateMessage(
      groupeId,
      messageId,
      UpdateGroupMessageDto(contenu: nouveauContenu),
    );

    print('✅ Message modifié');
    print('Nouveau contenu: ${updatedMessage.contenu}');
    print('is_edited: ${updatedMessage.isEdited}'); // true
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// EXEMPLE
void main() async {
  await modifierMessage(1, 42, 'Message corrigé !');
}
```

---

### **5. Supprimer un Message**

```dart
Future<void> supprimerMessage(int groupeId, int messageId) async {
  try {
    await GroupeMessageService.deleteMessage(groupeId, messageId);
    print('✅ Message supprimé');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// EXEMPLE
void main() async {
  await supprimerMessage(1, 42);
}
```

---

### **6. Épingler un Message (Admin/Modérateur)**

```dart
Future<void> epinglerMessage(int groupeId, int messageId) async {
  try {
    final message = await GroupeMessageService.pinMessage(
      groupeId,
      messageId,
    );

    if (message.isPinned) {
      print('✅ Message épinglé');
    } else {
      print('✅ Message désépinglé');
    }
  } catch (e) {
    print('❌ Erreur: $e (Vous devez être admin/modérateur)');
  }
}

// EXEMPLE
void main() async {
  await epinglerMessage(1, 42);
}
```

---

### **7. Consulter les Statistiques**

```dart
Future<void> afficherStatistiques(int groupeId) async {
  try {
    final stats = await GroupeMessageService.getMessagesStats(groupeId);

    print('📊 Statistiques du groupe:');
    print('  • Total messages: ${stats.totalMessages}');
    print('  • Messages non lus: ${stats.unreadMessages}');
    print('  • Messages épinglés: ${stats.pinnedMessages}');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

// EXEMPLE
void main() async {
  await afficherStatistiques(1);
}
```

---

## 📱 Exemple Complet : Page de Chat de Groupe

```dart
import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/groupe/groupe_message_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';

class GroupeChatPage extends StatefulWidget {
  final int groupeId;
  final String groupeName;

  const GroupeChatPage({
    Key? key,
    required this.groupeId,
    required this.groupeName,
  }) : super(key: key);

  @override
  State<GroupeChatPage> createState() => _GroupeChatPageState();
}

class _GroupeChatPageState extends State<GroupeChatPage> {
  List<GroupeMessageModel> _messages = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();

  int? _myId;
  String? _myType;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadMessages();
  }

  /// Charger les informations de l'utilisateur actuel
  Future<void> _loadUserInfo() async {
    final userType = await AuthBaseService.getUserType();
    final userData = await AuthBaseService.getUserData();

    setState(() {
      _myType = userType;
      _myId = userData['id'];
    });
  }

  /// Charger les messages du groupe
  Future<void> _loadMessages() async {
    try {
      final messages = await GroupeMessageService.getRecentMessages(
        widget.groupeId,
        limit: 100,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Marquer tous les messages comme lus
      await GroupeMessageService.markAllMessagesAsRead(widget.groupeId);
    } catch (e) {
      print('❌ Erreur chargement messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Envoyer un nouveau message
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final contenu = _messageController.text.trim();
    _messageController.clear();

    try {
      final message = await GroupeMessageService.sendSimpleMessage(
        widget.groupeId,
        contenu,
      );

      // Ajouter le message à la liste
      setState(() {
        _messages.add(message);
      });
    } catch (e) {
      print('❌ Erreur envoi message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'envoi du message')),
      );
    }
  }

  /// Modifier un message
  Future<void> _editMessage(GroupeMessageModel message) async {
    final controller = TextEditingController(text: message.contenu);

    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le message'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nouveau contenu',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Modifier'),
          ),
        ],
      ),
    );

    if (newContent != null && newContent.trim().isNotEmpty) {
      try {
        final updatedMessage = await GroupeMessageService.updateMessage(
          widget.groupeId,
          message.id,
          UpdateGroupMessageDto(contenu: newContent),
        );

        // Mettre à jour dans la liste
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de modification')),
        );
      }
    }
  }

  /// Supprimer un message
  Future<void> _deleteMessage(GroupeMessageModel message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le message'),
        content: Text('Voulez-vous vraiment supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await GroupeMessageService.deleteMessage(widget.groupeId, message.id);

        // Retirer de la liste
        setState(() {
          _messages.removeWhere((m) => m.id == message.id);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de suppression')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupeName),
        actions: [
          // Bouton statistiques
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () async {
              final stats = await GroupeMessageService.getMessagesStats(
                widget.groupeId,
              );
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Statistiques'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${stats.totalMessages}'),
                      Text('Non lus: ${stats.unreadMessages}'),
                      Text('Épinglés: ${stats.pinnedMessages}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Liste des messages
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = _myId != null &&
                          _myType != null &&
                          message.isSentByMe(_myId!, _myType!);

                      return _buildMessageBubble(message, isMine);
                    },
                  ),
                ),

                // Champ de saisie
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Tapez un message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(GroupeMessageModel message, bool isMine) {
    return GestureDetector(
      onLongPress: isMine
          ? () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifier'),
                      onTap: () {
                        Navigator.pop(context);
                        _editMessage(message);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer'),
                      onTap: () {
                        Navigator.pop(context);
                        _deleteMessage(message);
                      },
                    ),
                  ],
                ),
              );
            }
          : null,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom de l'expéditeur (si pas moi)
              if (!isMine)
                Text(
                  message.getSenderName(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

              // Contenu
              Text(
                message.contenu,
                style: TextStyle(
                  color: isMine ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: 4),

              // Heure + badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    GroupeMessageService.formatMessageTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (message.isPinned) ...[
                    SizedBox(width: 4),
                    Icon(Icons.push_pin, size: 12, color: Colors.amber),
                  ],
                  if (message.isEdited) ...[
                    SizedBox(width: 4),
                    Text(
                      'modifié',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: isMine ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 📊 Résumé des Méthodes

| Méthode | Description | Retour |
|---------|-------------|--------|
| `sendMessage()` | Envoyer un message | `GroupeMessageModel` |
| `sendSimpleMessage()` | Envoyer un message simple | `GroupeMessageModel` |
| `getMessagesByGroupe()` | Récupérer tous les messages | `List<GroupeMessageModel>` |
| `getUnreadMessages()` | Récupérer messages non lus | `List<GroupeMessageModel>` |
| `getPinnedMessages()` | Récupérer messages épinglés | `List<GroupeMessageModel>` |
| `getMessagesStats()` | Statistiques | `GroupeMessageStatsModel` |
| `markMessageAsRead()` | Marquer comme lu | `GroupeMessageModel` |
| `markAllMessagesAsRead()` | Marquer tout comme lu | `bool` |
| `updateMessage()` | Modifier un message | `GroupeMessageModel` |
| `deleteMessage()` | Supprimer un message | `void` |
| `pinMessage()` | Épingler/Désépingler | `GroupeMessageModel` |

---

## ✅ Checklist d'Implémentation

- [x] Service Flutter créé
- [x] Models conformes au backend
- [x] DTOs conformes au backend
- [x] Méthodes utilitaires (formatage dates, etc.)
- [x] Exemple complet de page de chat
- [x] Documentation complète

---

**Dernière mise à jour :** 2025-12-15
**Auteur :** Claude Code
