# Implémentation Posts et Messages dans les Profils

## ✅ Modifications effectuées

### 1. Service PostService - COMPLÉTÉ ✅

**Fichier** : `lib/services/posts/post_service.dart:387-399`

Ajout de la méthode `getPostsBySociete()` :

```dart
/// Récupérer les posts d'une société
/// GET /posts/societe/:societeId
static Future<List<PostModel>> getPostsBySociete(int societeId) async {
  final response = await ApiService.get('/posts/societe/$societeId');

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    final List<dynamic> postsData = jsonResponse['data'];
    return postsData.map((json) => PostModel.fromJson(json)).toList();
  } else {
    throw Exception('Erreur de récupération des posts de la société');
  }
}
```

---

## 📋 Modifications à faire manuellement

### 2. SocieteProfilePage - Ajouter Tabs Posts + Messages

**Fichier** : `lib/iu/onglets/recherche/societe_profile_page.dart`

#### Étape 2.1 : Imports ajoutés ✅
```dart
import '../../../services/posts/post_service.dart';
import '../../../services/messagerie/conversation_service.dart';
import '../../../messagerie/conversation_detail_page.dart';
```

#### Étape 2.2 : Ajouter TabController ✅
```dart
class _SocieteProfilePageState extends State<SocieteProfilePage>
    with SingleTickerProviderStateMixin {  // ← Ajouté

  // ... existing variables ...

  // TabController pour Posts et Messages
  late TabController _tabController;  // ← Ajouté
```

#### Étape 2.3 : Modifier initState()
```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: _isAbonne ? 3 : 2, vsync: this); // ← Ajouter
  _loadSocieteProfile();
}
```

#### Étape 2.4 : Ajouter dispose()
```dart
@override
void dispose() {
  _tabController.dispose();  // ← Ajouter
  super.dispose();
}
```

#### Étape 2.5 : Modifier la structure du build()

Remplacer le `Column` actuel par un structure avec `TabBar` et `TabBarView` :

```dart
@override
Widget build(BuildContext context) {
  if (_isLoading) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Profil Société'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  if (_societe == null) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Profil Société'),
      ),
      body: const Center(child: Text('Société introuvable')),
    );
  }

  return Scaffold(
    backgroundColor: const Color(0xFFF4F4F4),
    appBar: AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      title: Text(_societe!.nom),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        tabs: [
          const Tab(text: "Infos"),
          const Tab(text: "Posts"),
          if (_isAbonne) const Tab(text: "Messages"),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: [
        _buildInfoTab(),
        _buildPostsTab(),
        if (_isAbonne) _buildMessagesTab(),
      ],
    ),
  );
}
```

#### Étape 2.6 : Créer _buildInfoTab()

Déplacer le contenu actuel du body dans cette méthode :

```dart
Widget _buildInfoTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Header (Avatar + Nom + Secteur)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Avatar
              EditableProfileAvatar(
                photoUrl: _societe!.profile?.logo,
                size: 80,
                editable: false,
                onPhotoUpdated: (url) {},
              ),
              const SizedBox(height: 12),
              // Nom
              Text(
                _societe!.nom,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Secteur
              if (_societe!.secteurActivite != null)
                Text(
                  _societe!.secteurActivite!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Boutons d'action
        _buildActionButtons(),

        const SizedBox(height: 16),

        // Informations
        if (_societe!.email != null || _societe!.telephone != null || _societe!.adresse != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_societe!.email != null)
                  _buildInfoRow(Icons.email, 'Email', _societe!.email!),
                if (_societe!.telephone != null)
                  _buildInfoRow(Icons.phone, 'Téléphone', _societe!.telephone!),
                if (_societe!.adresse != null)
                  _buildInfoRow(Icons.location_on, 'Adresse', _societe!.adresse!),
              ],
            ),
          ),

        // Badge Premium si abonné
        if (_isAbonne) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffFFA500), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xffFFA500)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Vous avez un abonnement premium avec cette société',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
```

#### Étape 2.7 : Créer _buildPostsTab()

```dart
Widget _buildPostsTab() {
  return FutureBuilder<List<PostModel>>(
    future: PostService.getPostsBySociete(widget.societeId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: ${snapshot.error}'),
            ],
          ),
        );
      }

      final posts = snapshot.data ?? [];

      if (posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun post pour le moment',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(post);
        },
      );
    },
  );
}

Widget _buildPostCard(PostModel post) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor,
              child: Text(
                post.getAuthorName()[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.getAuthorName(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Contenu
        Text(post.contenu),
        const SizedBox(height: 12),
        // Actions
        Row(
          children: [
            Icon(Icons.favorite_border, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('${post.likesCount}'),
            const SizedBox(width: 20),
            Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text('${post.commentsCount}'),
          ],
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays > 0) {
    return '${diff.inDays}j';
  } else if (diff.inHours > 0) {
    return '${diff.inHours}h';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes}min';
  } else {
    return 'maintenant';
  }
}
```

#### Étape 2.8 : Créer _buildMessagesTab()

```dart
Widget _buildMessagesTab() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.message_outlined, size: 80, color: primaryColor),
        const SizedBox(height: 24),
        const Text(
          'Messagerie Premium',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Envoyez des messages privés à cette société',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _startConversation(),
          icon: const Icon(Icons.send),
          label: const Text('Envoyer un message'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    ),
  );
}

Future<void> _startConversation() async {
  try {
    // Créer ou récupérer la conversation
    final conversation = await ConversationService.createOrGetConversation(
      CreateConversationDto(
        participantId: widget.societeId,
        participantType: 'Societe',
      ),
    );

    // Naviguer vers la page de conversation
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationDetailPage(
            conversationId: conversation.id,
            participantName: _societe!.nom,
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

### 3. GroupeProfilePage - Ajouter Tabs Posts + Messages

**Fichier** : `lib/iu/onglets/recherche/groupe_profile_page.dart`

#### Étape 3.1 : Imports à ajouter

```dart
import '../../../services/posts/post_service.dart';
import '../../../services/groupe/groupe_message_service.dart';
import '../../../groupe/groupe_chat_page.dart';  // Si existe, sinon créer
```

#### Étape 3.2 : Modifier TabController

```dart
// Dans initState()
_tabController = TabController(length: 4, vsync: this); // 2 → 4 tabs
```

#### Étape 3.3 : Ajouter les tabs

```dart
bottom: TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: "Infos"),
    Tab(text: "Posts"),      // ← NOUVEAU
    Tab(text: "Messages"),   // ← NOUVEAU
    Tab(text: "Membres"),
  ],
),
```

#### Étape 3.4 : Ajouter les vues

```dart
body: TabBarView(
  controller: _tabController,
  children: [
    _buildInfoTab(),
    _buildPostsTab(),      // ← NOUVEAU
    _buildMessagesTab(),   // ← NOUVEAU
    _buildMembresTab(),
  ],
),
```

#### Étape 3.5 : Créer _buildPostsTab()

```dart
Widget _buildPostsTab() {
  return FutureBuilder<List<PostModel>>(
    future: PostService.getPostsByGroupe(widget.groupeId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Erreur: ${snapshot.error}'));
      }

      final posts = snapshot.data ?? [];

      if (posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Aucun post dans ce groupe'),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return _buildPostCard(posts[index]);
        },
      );
    },
  );
}

Widget _buildPostCard(PostModel post) {
  // Même code que SocieteProfilePage
  // ... (copier depuis l'étape 2.7)
}
```

#### Étape 3.6 : Créer _buildMessagesTab()

```dart
Widget _buildMessagesTab() {
  if (!_isMember) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Rejoignez le groupe pour accéder aux messages'),
        ],
      ),
    );
  }

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.chat_outlined, size: 80, color: primaryColor),
        const SizedBox(height: 24),
        const Text(
          'Discussion du groupe',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _openGroupChat(),
          icon: const Icon(Icons.chat),
          label: const Text('Ouvrir la discussion'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    ),
  );
}

void _openGroupChat() {
  // Si GroupeChatPage existe :
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GroupeChatPage(
        groupeId: widget.groupeId,
        groupeName: _groupe!.nom,
      ),
    ),
  );

  // Sinon, implémenter une page de chat simple ici
}
```

---

## 📝 Notes importantes

1. **Backend** : Assurez-vous que le backend a l'endpoint `/posts/societe/:id`
2. **Permissions** : Messages groupe uniquement pour les membres
3. **Messages Société** : Uniquement pour les abonnés premium
4. **Ordre des tabs** :
   - Société : Infos, Posts, Messages (si abonné)
   - Groupe : Infos, Posts, Messages, Membres

---

## ✅ Checklist de vérification

- [x] PostService.getPostsBySociete() ajouté
- [ ] SocieteProfilePage avec 3 tabs
- [ ] GroupeProfilePage avec 4 tabs
- [ ] Tests de navigation
- [ ] Tests de permissions (membre/abonné)
