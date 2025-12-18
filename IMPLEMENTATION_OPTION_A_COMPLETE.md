# ✅ Implémentation Option A - Posts et Messages Séparés

## 📋 Vue d'ensemble

Cette documentation récapitule l'implémentation de l'**Option A** : séparation des Posts et Messages dans des onglets distincts pour les pages de profil Groupe et Société.

---

## 🎯 Structure Implémentée

### **1. Page Groupe (GroupeProfilePage)**

**Fichier** : [lib/iu/onglets/recherche/groupe_profile_page.dart](lib/iu/onglets/recherche/groupe_profile_page.dart)

#### Structure des onglets :
```
┌─────────────────────────────────────┐
│  Groupe: [Nom du groupe]            │
├─────────┬────────┬──────────┬───────┤
│  Infos  │ Posts  │ Messages │Membres│
└─────────┴────────┴──────────┴───────┘
```

**4 onglets :**
1. **Infos** : Informations du groupe, statistiques, description, règles
2. **Posts** : Publications publiques du groupe (via `PostService.getPostsByGroupe()`)
3. **Messages** : Chat/discussion du groupe (accessible uniquement aux membres)
4. **Membres** : Liste des membres avec leurs rôles

#### Permissions Messages :
- ✅ **Membre** : Accès au chat du groupe
- ❌ **Non-membre** : Message "Rejoignez le groupe pour accéder aux messages"

---

### **2. Page Société (SocieteProfilePage)**

**Fichier** : [lib/iu/onglets/recherche/societe_profile_page.dart](lib/iu/onglets/recherche/societe_profile_page.dart)

#### Structure des onglets :
```
┌─────────────────────────────────────┐
│  Société: [Nom de la société]       │
├─────────┬────────┬──────────────────┤
│  Infos  │ Posts  │ Messages (premium)
└─────────┴────────┴──────────────────┘
```

**2 ou 3 onglets (dynamique) :**
1. **Infos** : Informations société, produits, services, coordonnées
2. **Posts** : Publications de la société (via `PostService.getPostsBySociete()`)
3. **Messages** : Messagerie privée (visible **uniquement si abonné premium**)

#### Permissions Messages :
- ✅ **Abonné premium** : Accès à la messagerie privée avec la société
- ❌ **Non-abonné** : Onglet Messages **non visible**

---

## 📂 Modifications Apportées

### **GroupeProfilePage**

#### 1. Imports ajoutés
```dart
import '../../../services/posts/post_service.dart';
import '../../../groupe/groupe_chat_page.dart';
```

#### 2. TabController modifié
```dart
_tabController = TabController(length: 4, vsync: this); // 2 → 4 onglets
```

#### 3. Tabs dans l'AppBar
```dart
tabs: const [
  Tab(text: 'Infos', icon: Icon(Icons.info_outline, size: 20)),
  Tab(text: 'Posts', icon: Icon(Icons.article_outlined, size: 20)),
  Tab(text: 'Messages', icon: Icon(Icons.chat_outlined, size: 20)),
  Tab(text: 'Membres', icon: Icon(Icons.people_outline, size: 20)),
],
```

#### 4. Nouvelles méthodes ajoutées
- `_buildPostsTab()` : Affiche les posts du groupe avec FutureBuilder
- `_buildPostCard(PostModel post)` : Card de post avec auteur, contenu, likes, commentaires
- `_buildMessagesTab()` : Interface pour ouvrir le chat groupe
- `_openGroupChat()` : Navigation vers GroupeChatPage
- `_formatPostDate(DateTime date)` : Format relatif (2j, 3h, 5min)

---

### **SocieteProfilePage**

#### 1. TabController dynamique
```dart
// Initialisé après chargement du profil
_tabController = TabController(
  length: _isAbonne ? 3 : 2, // 3 onglets si abonné, 2 sinon
  vsync: this,
);
```

#### 2. Tabs dynamiques dans l'AppBar
```dart
tabs: [
  const Tab(text: 'Infos', icon: Icon(Icons.info_outline, size: 20)),
  const Tab(text: 'Posts', icon: Icon(Icons.article_outlined, size: 20)),
  if (_isAbonne) const Tab(text: 'Messages', icon: Icon(Icons.chat_outlined, size: 20)),
],
```

#### 3. TabBarView dynamique
```dart
children: [
  _buildInfoTab(),
  _buildPostsTab(),
  if (_isAbonne) _buildMessagesTab(),
],
```

#### 4. Nouvelles méthodes ajoutées
- `_buildInfoTab()` : Contenu original déplacé dans un onglet
- `_buildPostsTab()` : Affiche les posts de la société avec FutureBuilder
- `_buildPostCard(PostModel post)` : Card de post identique au groupe
- `_buildMessagesTab()` : Interface pour démarrer une conversation
- `_startConversation()` : Crée/récupère conversation et navigue vers ConversationDetailPage
- `_formatPostDate(DateTime date)` : Format relatif identique au groupe

#### 5. Gestion du dispose
```dart
@override
void dispose() {
  if (_societe != null) {
    _tabController.dispose();
  }
  super.dispose();
}
```

---

## 🔧 Services Utilisés

### PostService
```dart
// Pour les groupes
Future<List<PostModel>> PostService.getPostsByGroupe(int groupeId)

// Pour les sociétés
Future<List<PostModel>> PostService.getPostsBySociete(int societeId)
```

### ConversationService (Société)
```dart
Future<ConversationModel> ConversationService.createOrGetConversation(
  CreateConversationDto dto,
)
```

### GroupeChatPage (Groupe)
```dart
GroupeChatPage(
  groupeId: int,
  groupeName: String,
)
```

---

## 🎨 UI/UX

### Affichage des Posts
- **État de chargement** : CircularProgressIndicator
- **Erreur** : Icône error + message d'erreur
- **Vide** : Icône article + "Aucun post"
- **Liste** : Cards avec :
  - Avatar auteur
  - Nom auteur
  - Date relative (2j, 3h, 5min)
  - Contenu du post
  - Compteurs likes et commentaires

### Messages Groupe
- **Non-membre** : 🔒 Message "Rejoignez le groupe"
- **Membre** : 💬 Bouton "Ouvrir la discussion"

### Messages Société
- **Onglet visible uniquement si abonné premium**
- **Interface** : 💌 Bouton "Envoyer un message"
- **Action** : Crée conversation et navigue vers page de chat

---

## ✅ Tests à Effectuer

### GroupeProfilePage
- [ ] Affichage correct des 4 onglets
- [ ] Chargement des posts du groupe
- [ ] Messages accessible uniquement aux membres
- [ ] Navigation vers GroupeChatPage fonctionne
- [ ] Format de date relatif correct

### SocieteProfilePage
- [ ] 2 onglets (Infos, Posts) si non-abonné
- [ ] 3 onglets (Infos, Posts, Messages) si abonné premium
- [ ] Chargement des posts de la société
- [ ] Création de conversation fonctionne
- [ ] Navigation vers ConversationDetailPage
- [ ] TabController dispose correctement

---

## 📊 Comparaison avec Option B

| Critère | Option A (Implémenté) | Option B (Non implémenté) |
|---------|----------------------|---------------------------|
| **Structure** | Posts et Messages séparés | Posts et Messages mélangés |
| **Clarté UX** | ✅ Excellente | ⚠️ Peut prêter à confusion |
| **Scalabilité** | ✅ Facile d'ajouter features | ⚠️ Plus difficile |
| **Cohérence** | ✅ Cohérent Groupe/Société | ❌ Différent Groupe/Société |
| **Complexité** | ⚠️ Plus d'onglets | ✅ Moins d'onglets |

---

## 🚀 Fonctionnalités Futures

### Posts
- [ ] Ajouter possibilité de liker un post
- [ ] Ajouter possibilité de commenter
- [ ] Ajouter images/médias dans les posts
- [ ] Filtrer par type de post

### Messages
- [ ] Notifications en temps réel
- [ ] Indicateur de nouveaux messages
- [ ] Compteur de messages non lus
- [ ] Recherche dans les messages

---

## 📝 Notes Importantes

1. **GroupeProfilePage** : Le TabController est toujours de longueur 4
2. **SocieteProfilePage** : Le TabController est **dynamique** (2 ou 3 selon abonnement)
3. **Permissions** :
   - Messages Groupe : Réservé aux membres
   - Messages Société : Réservé aux abonnés premium
4. **Backend** : S'assurer que les endpoints `/posts/groupe/:id` et `/posts/societe/:id` existent

---

## ✅ Statut Final

| Tâche | Statut |
|-------|--------|
| GroupeProfilePage - Ajout onglets Posts et Messages | ✅ Terminé |
| SocieteProfilePage - Ajout onglets Posts et Messages | ✅ Terminé |
| Gestion permissions Messages | ✅ Terminé |
| TabController dynamique Société | ✅ Terminé |
| Format date relatif | ✅ Terminé |
| Navigation vers pages chat | ✅ Terminé |

---

**Date d'implémentation** : 2025-12-17
**Version** : 1.0
**Statut** : ✅ **COMPLET**
