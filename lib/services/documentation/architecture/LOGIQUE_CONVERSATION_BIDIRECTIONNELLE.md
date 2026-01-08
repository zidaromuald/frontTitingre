# 💬 Logique de Conversation Bidirectionnelle - User ↔ Société

## 📋 Vue d'ensemble

Ce document décrit la logique complète de conversation entre utilisateurs et sociétés dans l'application, implémentée dans les pages ServicePlan (IU et IS).

---

## ✅ Implémentation complète

### 🔵 **1. IU (User) → Société** - Page ServicePlan User

**Fichier :** [lib/iu/onglets/servicePlan/service.dart](lib/iu/onglets/servicePlan/service.dart)

#### Flux utilisateur :
1. **User** se connecte à l'application
2. Accède à l'onglet **ServicePlan** → **Société**
3. Voit la liste des sociétés suivies (gratuit) + sociétés avec abonnement premium
4. **Clique sur une société** → Modal bottom sheet s'affiche avec :
   - ✅ **Voir le profil** : Navigation vers `SocieteProfilePage`
   - ✅ **Envoyer un message** :
     - Disponible **UNIQUEMENT** si abonnement premium actif
     - Crée ou récupère une conversation via `ConversationService.createOrGetConversation()`
     - Navigation vers `ConversationDetailPage`

#### Méthodes clés :
```dart
// Ligne 618-743
void _showSocieteOptionsDialog(SocieteModel societe) {
  // Affiche modal avec 2 options
}

// Ligne 745-794
Future<void> _startConversationWithSociete(SocieteModel societe) async {
  final conversation = await ConversationService.createOrGetConversation(
    CreateConversationDto(
      participantId: societe.id,
      participantType: 'Societe',  // User → Société
    ),
  );
}
```

#### Règle métier importante :
- **L'option "Envoyer un message" est CONDITIONNELLE** :
  - ✅ **Activée** : Si `isPremium = true` (utilisateur a un abonnement actif avec cette société)
  - ❌ **Désactivée** : Si `isPremium = false` (affichage grisé avec message "Nécessite un abonnement premium")

---

### 🟢 **2. IS (Société) → User** - Page ServicePlan Société

**Fichier :** [lib/is/onglets/servicePlan/service.dart](lib/is/onglets/servicePlan/service.dart)

#### Flux société :
1. **Société** (admin) se connecte à l'application
2. Accède à l'onglet **ServicePlan** → **Suivie**
3. Voit la liste des utilisateurs :
   - Followers gratuits (suivent la société)
   - Abonnés premium (badge étoile dorée)
4. **Clique sur un utilisateur** → Modal bottom sheet s'affiche avec :
   - ✅ **Voir le profil** : Navigation vers `UserProfilePage`
   - ✅ **Envoyer un message** :
     - Disponible pour **TOUS les utilisateurs** (gratuits et premium)
     - Crée ou récupère une conversation via `ConversationService.createOrGetConversation()`
     - Navigation vers `ConversationDetailPage`

#### Méthodes clés :
```dart
// Ligne 440-541
void _showUserOptionsDialog(UserModel user) {
  // Affiche modal avec 2 options
}

// Ligne 543-592
Future<void> _startConversation(UserModel user) async {
  final conversation = await ConversationService.createOrGetConversation(
    CreateConversationDto(
      participantId: user.id,
      participantType: 'User',  // Société → User
    ),
  );
}
```

#### Règle métier importante :
- **L'option "Envoyer un message" est TOUJOURS DISPONIBLE** :
  - ✅ Société peut contacter n'importe quel follower (gratuit ou premium)
  - Pas de restriction basée sur l'abonnement

---

## 🔄 Architecture de la conversation

### Service utilisé : `ConversationService`

**Fichier :** [lib/services/messagerie/conversation_service.dart](lib/services/messagerie/conversation_service.dart)

```dart
static Future<ConversationModel> createOrGetConversation(
  CreateConversationDto dto,
) async {
  // POST /conversations
  // Si une conversation existe déjà, la retourne
  // Sinon, crée une nouvelle conversation
}
```

### DTO (Data Transfer Object) :
```dart
class CreateConversationDto {
  final int participantId;       // ID du participant (User ou Société)
  final String participantType;  // 'User' ou 'Societe'
}
```

---

## 📱 Page de conversation : `ConversationDetailPage`

**Fichier :** [lib/messagerie/conversation_detail_page.dart](lib/messagerie/conversation_detail_page.dart)

### Fonctionnalités :
- 💬 Affichage des messages en temps réel (rafraîchissement toutes les 5 secondes)
- ✉️ Envoi de messages
- 🎨 Design style Mattermost avec bulles de messages
- 🔄 Auto-scroll vers le dernier message
- ⏱️ Format d'heure intelligent ("À l'instant", "Il y a Xm", etc.)
- 📱 Interface responsive avec SafeArea

### Service utilisé : `MessageService`

**Fichier :** [lib/services/messagerie/message_service.dart](lib/services/messagerie/message_service.dart)

```dart
// Envoyer un message
static Future<MessageModel> sendMessage(
  int conversationId,
  SendMessageDto dto,
)

// Récupérer les messages d'une conversation
static Future<List<MessageModel>> getMessagesByConversation(
  int conversationId,
)
```

---

## 🔐 Règles de gestion des conversations

### 1. **Création de conversation**

| Scénario | Participant 1 | Participant 2 | Condition | Résultat |
|----------|---------------|---------------|-----------|----------|
| User → Société | User (type: 'User') | Société (type: 'Societe') | ✅ Abonnement premium actif | ✅ Conversation créée |
| User → Société | User (type: 'User') | Société (type: 'Societe') | ❌ Pas d'abonnement | ❌ Bouton désactivé |
| Société → User | Société (type: 'Societe') | User (type: 'User') | ✅ Toujours | ✅ Conversation créée |

### 2. **Réutilisation de conversation**

Si une conversation existe déjà entre deux participants, elle est **réutilisée** au lieu d'en créer une nouvelle.

```dart
// Backend vérifie si une conversation existe déjà
// Si oui : retourne la conversation existante
// Si non : crée une nouvelle conversation
```

### 3. **Messages liés à un abonnement**

Les messages peuvent être liés à :
- Un abonnement (`abonnement_id`)
- Une transaction (`transaction_id`)

```dart
class SendMessageDto {
  final String contenu;
  final int? transactionId;  // Optionnel
  final int? abonnementId;   // Optionnel
}
```

---

## 📊 Comparaison des deux flux

| Aspect | IU (User → Société) | IS (Société → User) |
|--------|---------------------|---------------------|
| **Accès conversation** | ⚠️ **Conditionnel** (premium requis) | ✅ **Toujours disponible** |
| **Type participant** | `participantType: 'Societe'` | `participantType: 'User'` |
| **Badge premium** | ⭐ Sur les sociétés avec abonnement | ⭐ Sur les users abonnés |
| **Option messagerie** | Désactivée si pas premium | Toujours activée |
| **Message UX** | "Nécessite un abonnement premium" | "Envoyer un message" |

---

## 🎯 Logique métier résumée

### ✅ User peut envoyer un message à une Société SI ET SEULEMENT SI :
1. Il a un **abonnement premium actif** avec cette société
2. L'abonnement est dans la table `abonnements` avec `statut = 'actif'`
3. La société apparaît dans `_societeIdsAbonnees` (Set des IDs de sociétés abonnées)

### ✅ Société peut envoyer un message à un User :
1. **TOUJOURS** - Pas de restriction
2. Peu importe si l'user est un simple follower ou un abonné premium
3. Permet à la société de contacter tous ses followers

---

## 🔧 Endpoints API utilisés

### Conversations
- `POST /conversations` - Créer ou récupérer une conversation
- `GET /conversations` - Récupérer mes conversations actives
- `GET /conversations/:id` - Récupérer une conversation par ID

### Messages
- `POST /messages/conversations/:conversationId` - Envoyer un message
- `GET /messages/conversations/:conversationId` - Récupérer les messages

### Abonnements (pour vérification premium)
- `GET /abonnements/my-subscriptions?statut=actif` - Mes abonnements actifs (User)
- `GET /abonnements/my-subscribers?statut=actif` - Mes abonnés actifs (Société)

---

## 🎨 Captures d'écran de l'UX

### User clique sur Société (IU)
```
┌─────────────────────────────────────┐
│  [Logo]  Nom de la société      ⭐  │
│          Secteur d'activité          │
├─────────────────────────────────────┤
│  🏢 Voir le profil                  │
├─────────────────────────────────────┤
│  💬 Envoyer un message              │
│     Disponible avec abonnement      │
│     premium ⭐                       │
└─────────────────────────────────────┘
```

### Société clique sur User (IS)
```
┌─────────────────────────────────────┐
│  [Avatar]  Nom Prénom           ⭐  │
│            email@example.com        │
├─────────────────────────────────────┤
│  👤 Voir le profil                  │
├─────────────────────────────────────┤
│  💬 Envoyer un message              │
└─────────────────────────────────────┘
```

---

## ✅ Checklist de validation

- [x] User peut voir profil société
- [x] User peut envoyer message à société (si premium)
- [x] User ne peut PAS envoyer message sans premium
- [x] Société peut voir profil user
- [x] Société peut envoyer message à tout user
- [x] Conversations réutilisées si elles existent
- [x] Page conversation fonctionne bidirectionnellement
- [x] Messages en temps réel (polling 5s)
- [x] Indicateurs de chargement présents
- [x] Gestion des erreurs avec SnackBar

---

## 🚀 Prochaines améliorations possibles

1. **WebSocket pour messages en temps réel** (au lieu de polling)
2. **Notifications push** pour nouveaux messages
3. **Indicateur "En train d'écrire..."**
4. **Marquage automatique comme lu** quand conversation ouverte
5. **Support pièces jointes** (images, documents)
6. **Recherche dans les messages**
7. **Archivage de conversations**

---

**Dernière mise à jour :** 2025-12-13
**Fichiers modifiés :**
- [lib/iu/onglets/servicePlan/service.dart](lib/iu/onglets/servicePlan/service.dart) (Lignes 618-794)
- [lib/is/onglets/servicePlan/service.dart](lib/is/onglets/servicePlan/service.dart) (Lignes 440-592)
- [lib/messagerie/conversation_detail_page.dart](lib/messagerie/conversation_detail_page.dart) (Nouveau fichier)
