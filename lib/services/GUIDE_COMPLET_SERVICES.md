# Guide Complet d'Utilisation des Services GestAuth

Ce guide explique **concrètement** quand et comment utiliser chaque service de l'application dans votre frontend Flutter.

## 📚 Table des matières

1. [Services d'authentification](#1-services-dauthentification)
2. [Services de relations sociales](#2-services-de-relations-sociales)
3. [Services de posts](#3-services-de-posts)
4. [Services de messagerie](#4-services-de-messagerie)
5. [Services de groupes](#5-services-de-groupes)
6. [Flux d'utilisation complets](#6-flux-dutilisation-complets)

---

## 1. Services d'authentification

📖 **Documentation détaillée** : [GUIDE_UTILISATION_AUTH.md](AuthUS/GUIDE_UTILISATION_AUTH.md)

### Résumé rapide

| Service | Endpoint | Quand l'utiliser |
|---------|----------|------------------|
| `UserAuthService.login()` | Connexion utilisateur | Page de connexion |
| `UserAuthService.register()` | Inscription utilisateur | Page d'inscription |
| `UserAuthService.getMyProfile()` | **Mon** profil | Page "Mon compte", paramètres |
| `UserAuthService.getUserProfile(id)` | Profil d'un **autre** utilisateur | Recherche, clic sur un utilisateur |
| `SocieteAuthService.login()` | Connexion société | Page de connexion entreprise |
| `SocieteAuthService.getSocieteProfile(id)` | Profil d'une société | Voir une entreprise |

---

## 2. Services de relations sociales

Les services de relations gèrent les abonnements, suivis, invitations et demandes d'abonnement.

### 📁 Fichiers
- [suivre_service.dart](suivre/suivre_service.dart) - Suivre/Ne plus suivre
- [invitation_service.dart](suivre/invitation_service.dart) - Invitations
- [demande_abonnement_service.dart](suivre/demande_abonnement_service.dart) - Demandes d'abonnement
- [abonnement_service.dart](suivre/abonnement_service.dart) - Abonnements

---

### A. SuivreService - Suivre des utilisateurs/sociétés

#### `suivreUser(userId)` - Suivre un utilisateur

**Quand l'utiliser ?**
- Clic sur le bouton "Suivre" sur un profil utilisateur
- Sur la page de profil de quelqu'un

```dart
// Widget: lib/widgets/follow_button.dart
class FollowButton extends StatefulWidget {
  final int userId;
  final bool isFollowing;

  const FollowButton({required this.userId, required this.isFollowing});

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  late bool _isFollowing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);

    try {
      if (_isFollowing) {
        // Ne plus suivre
        await SuivreService.unfollowUser(widget.userId);
        setState(() => _isFollowing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous ne suivez plus cet utilisateur')),
        );
      } else {
        // Suivre
        await SuivreService.suivreUser(widget.userId);
        setState(() => _isFollowing = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vous suivez maintenant cet utilisateur')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _toggleFollow,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_isFollowing ? Icons.check : Icons.person_add),
      label: Text(_isFollowing ? 'Abonné' : 'Suivre'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isFollowing ? Colors.grey : Colors.blue,
      ),
    );
  }
}
```

#### `getMySuivis()` - Liste des personnes que je suis

**Quand l'utiliser ?**
- Page "Abonnements" dans mon profil
- Onglet "Personnes que je suis"

```dart
// Page: lib/pages/profile/my_followings_page.dart
class MyFollowingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Abonnements')),
      body: FutureBuilder<List<SuivreModel>>(
        future: SuivreService.getMySuivis(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final suivis = snapshot.data!;

          if (suivis.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Vous ne suivez personne pour le moment'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: suivis.length,
            itemBuilder: (context, index) {
              final suivi = suivis[index];
              final suiviData = suivi.suiviUser ?? suivi.suiviSociete;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: suiviData?.photoProfil != null
                      ? NetworkImage(suiviData!.photoProfil!)
                      : null,
                ),
                title: Text(suiviData?.nom ?? 'Utilisateur'),
                subtitle: Text(
                  suivi.suiviType == 'User' ? 'Utilisateur' : 'Société',
                ),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () async {
                    // Ne plus suivre
                    if (suivi.suiviType == 'User') {
                      await SuivreService.unfollowUser(suivi.suiviId);
                    } else {
                      await SuivreService.unfollowSociete(suivi.suiviId);
                    }
                    // Rafraîchir la page
                    (context as Element).markNeedsBuild();
                  },
                ),
                onTap: () {
                  // Naviguer vers le profil
                  if (suivi.suiviType == 'User') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(userId: suivi.suiviId),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyProfilePage(societeId: suivi.suiviId),
                      ),
                    );
                  }
                },
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

### B. InvitationService - Gérer les invitations

#### `getMyInvitations()` - Mes invitations reçues

**Quand l'utiliser ?**
- Page "Invitations"
- Badge de notification d'invitations en attente

```dart
// Page: lib/pages/invitations/invitations_page.dart
class InvitationsPage extends StatefulWidget {
  @override
  _InvitationsPageState createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  List<InvitationModel>? _invitations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    try {
      final invitations = await InvitationService.getMyInvitations();
      setState(() {
        _invitations = invitations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvitation(int invitationId) async {
    try {
      await InvitationService.acceptInvitation(invitationId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation acceptée')),
      );
      _loadInvitations(); // Rafraîchir
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _declineInvitation(int invitationId) async {
    try {
      await InvitationService.declineInvitation(invitationId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation refusée')),
      );
      _loadInvitations(); // Rafraîchir
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Invitations')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pendingInvitations = InvitationService.filterPendingInvitations(_invitations!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invitations (${pendingInvitations.length})'),
      ),
      body: pendingInvitations.isEmpty
          ? Center(child: Text('Aucune invitation en attente'))
          : ListView.builder(
              itemCount: pendingInvitations.length,
              itemBuilder: (context, index) {
                final invitation = pendingInvitations[index];
                final inviteur = invitation.inviteurUser ?? invitation.inviteurSociete;

                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: inviteur?.photoProfil != null
                          ? NetworkImage(inviteur!.photoProfil!)
                          : null,
                    ),
                    title: Text('${inviteur?.nom} vous a invité'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (invitation.message != null)
                          Text(invitation.message!),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.check, size: 16),
                              label: Text('Accepter'),
                              onPressed: () => _acceptInvitation(invitation.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            SizedBox(width: 8),
                            TextButton.icon(
                              icon: Icon(Icons.close, size: 16),
                              label: Text('Refuser'),
                              onPressed: () => _declineInvitation(invitation.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

#### Badge de notification

```dart
// Widget: lib/widgets/notification_badge.dart
class InvitationsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvitationModel>>(
      future: InvitationService.getMyInvitations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/invitations');
            },
          );
        }

        final pending = InvitationService.filterPendingInvitations(snapshot.data!);
        final count = pending.length;

        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.pushNamed(context, '/invitations');
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
```

---

## 3. Services de posts

### 📁 Fichiers
- [post_service.dart](posts/post_service.dart) - Créer, lire, modifier, supprimer des posts
- [comment_service.dart](posts/comment_service.dart) - Commenter
- [like_service.dart](posts/like_service.dart) - Liker

---

### A. PostService - Gérer les publications

#### `createPost()` - Créer un nouveau post

**Quand l'utiliser ?**
- Page de création de post
- Bouton "Publier" / "Nouveau post"

```dart
// Page: lib/pages/posts/create_post_page.dart
class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contenuController = TextEditingController();
  List<String> _mediaUrls = [];
  bool _isLoading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Upload des images
      for (final image in images) {
        final url = await PostService.uploadMedia(image.path, 'image');
        _mediaUrls.add(url);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'upload: ${e.toString()}')),
      );
    }
  }

  Future<void> _publishPost() async {
    if (_contenuController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le contenu ne peut pas être vide')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final post = await PostService.createPost(
        contenu: _contenuController.text.trim(),
        media: _mediaUrls,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post publié avec succès')),
      );

      Navigator.pop(context, post); // Retourner le post créé
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouveau post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishPost,
            child: Text('Publier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _contenuController,
              decoration: InputDecoration(
                hintText: 'Quoi de neuf ?',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: null,
            ),
          ),
          if (_mediaUrls.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaUrls.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Image.network(
                          _mediaUrls[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() => _mediaUrls.removeAt(index));
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Divider(),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo),
                onPressed: _isLoading ? null : _pickMedia,
              ),
              Text('Ajouter des photos'),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### `getMyFeed()` - Fil d'actualité

**Quand l'utiliser ?**
- Page d'accueil (HomePage)
- Onglet "Fil d'actualité"

```dart
// Page: lib/pages/home/feed_page.dart
class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<PostModel> _posts = [];
  bool _isLoading = false;
  int _page = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final posts = await PostService.getMyFeed(limit: 10, offset: 0);
      setState(() {
        _posts.clear();
        _posts.addAll(posts);
        _page = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newPosts = await PostService.getMyFeed(
        limit: 10,
        offset: _page * 10,
      );
      setState(() {
        _posts.addAll(newPosts);
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fil d\'actualité')),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _posts.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _posts.length) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return PostCard(post: _posts[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final newPost = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreatePostPage()),
          );
          if (newPost != null) {
            _loadPosts(); // Rafraîchir le fil
          }
        },
      ),
    );
  }
}
```

---

### B. LikeService - Liker des posts

#### `likePost()` / `unlikePost()` - Liker/Unliker

**Quand l'utiliser ?**
- Clic sur le bouton "J'aime" d'un post

```dart
// Widget: lib/widgets/post_card.dart
class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({required this.post});

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe ?? false;
    _likesCount = widget.post.likesCount ?? 0;
  }

  Future<void> _toggleLike() async {
    try {
      if (_isLiked) {
        await LikeService.unlikePost(widget.post.id);
        setState(() {
          _isLiked = false;
          _likesCount--;
        });
      } else {
        await LikeService.likePost(widget.post.id);
        setState(() {
          _isLiked = true;
          _likesCount++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec auteur
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.auteur?.photoProfil != null
                  ? NetworkImage(widget.post.auteur!.photoProfil!)
                  : null,
            ),
            title: Text(widget.post.auteur?.nom ?? 'Utilisateur'),
            subtitle: Text(timeAgo(widget.post.createdAt)),
          ),

          // Contenu
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.post.contenu),
          ),

          // Media
          if (widget.post.media != null && widget.post.media!.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: widget.post.media!.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.post.media![index],
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),

          // Actions
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : null,
                ),
                onPressed: _toggleLike,
              ),
              Text('$_likesCount'),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.comment_outlined),
                onPressed: () {
                  // Ouvrir la page de commentaires
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostCommentsPage(post: widget.post),
                    ),
                  );
                },
              ),
              Text('${widget.post.commentsCount ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

### C. CommentService - Commenter

#### `commentPost()` - Ajouter un commentaire

**Quand l'utiliser ?**
- Page de détails d'un post
- Clic sur "Commenter"

```dart
// Page: lib/pages/posts/post_comments_page.dart
class PostCommentsPage extends StatefulWidget {
  final PostModel post;

  const PostCommentsPage({required this.post});

  @override
  _PostCommentsPageState createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends State<PostCommentsPage> {
  final _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await CommentService.getPostComments(widget.post.id);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      final comment = await CommentService.commentPost(
        postId: widget.post.id,
        contenu: _commentController.text.trim(),
      );

      setState(() {
        _comments.insert(0, comment);
        _commentController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Commentaires')),
      body: Column(
        children: [
          // Liste des commentaires
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment.auteur?.photoProfil != null
                              ? NetworkImage(comment.auteur!.photoProfil!)
                              : null,
                        ),
                        title: Text(comment.auteur?.nom ?? 'Utilisateur'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment.contenu),
                            SizedBox(height: 4),
                            Text(
                              timeAgo(comment.createdAt),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Champ de saisie
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Services de messagerie

### 📁 Fichiers
- [conversation_service.dart](messaging/conversation_service.dart) - Gérer les conversations
- [message_service.dart](messaging/message_service.dart) - Envoyer/recevoir des messages

---

### A. ConversationService - Conversations

#### `createOrGetConversation()` - Créer ou récupérer une conversation

**Quand l'utiliser ?**
- Clic sur "Envoyer un message" sur un profil
- Démarrer une nouvelle conversation

```dart
// Bouton "Message" sur un profil utilisateur
ElevatedButton.icon(
  icon: Icon(Icons.message),
  label: Text('Envoyer un message'),
  onPressed: () async {
    try {
      // Créer ou récupérer la conversation avec cet utilisateur
      final conversation = await ConversationService.createOrGetConversation(
        participantId: userId, // ID de l'utilisateur
        participantType: 'User',
      );

      // Naviguer vers la page de conversation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationPage(conversation: conversation),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  },
)
```

#### `getMyConversations()` - Liste de mes conversations

**Quand l'utiliser ?**
- Page "Messages" / "Messagerie"
- Onglet "Conversations"

```dart
// Page: lib/pages/messages/conversations_list_page.dart
class ConversationsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: FutureBuilder<List<ConversationModel>>(
        future: ConversationService.getMyConversations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherParticipant = conv.participants.firstWhere(
                (p) => p.id != currentUserId, // currentUserId = utilisateur connecté
              );

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: otherParticipant.photoProfil != null
                          ? NetworkImage(otherParticipant.photoProfil!)
                          : null,
                    ),
                    if (conv.unreadCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(otherParticipant.nom ?? 'Utilisateur'),
                subtitle: Text(
                  conv.lastMessage?.contenu ?? 'Aucun message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: conv.unreadCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  conv.lastMessage != null
                      ? timeAgo(conv.lastMessage!.createdAt)
                      : '',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationPage(conversation: conv),
                    ),
                  );
                },
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

### B. MessageService - Envoyer des messages

#### `sendMessage()` - Envoyer un message

**Quand l'utiliser ?**
- Dans une conversation
- Clic sur "Envoyer"

```dart
// Page: lib/pages/messages/conversation_page.dart
class ConversationPage extends StatefulWidget {
  final ConversationModel conversation;

  const ConversationPage({required this.conversation});

  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _messageController = TextEditingController();
  final List<MessageModel> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markAsRead();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await MessageService.getMessagesByConversation(
        widget.conversation.id,
      );
      setState(() {
        _messages.addAll(messages.reversed); // Du plus ancien au plus récent
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    try {
      await MessageService.markAllAsRead(widget.conversation.id);
    } catch (e) {
      // Ignorer l'erreur
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final message = await MessageService.sendMessage(
        conversationId: widget.conversation.id,
        contenu: _messageController.text.trim(),
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
      });

      // Scroller vers le bas
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  void _scrollToBottom() {
    // Implémenter le scroll vers le bas
  }

  @override
  Widget build(BuildContext context) {
    final otherParticipant = widget.conversation.participants.firstWhere(
      (p) => p.id != currentUserId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(otherParticipant.nom ?? 'Conversation'),
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message.senderId == currentUserId;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.contenu,
                            style: TextStyle(
                              color: isMine ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Champ de saisie
          Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
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
}
```

---

## 5. Services de groupes

### 📁 Fichiers
- [groupe_service.dart](groupe/groupe_service.dart) - Gérer les groupes
- [groupe_invitation_service.dart](groupe/groupe_invitation_service.dart) - Invitations groupe
- [groupe_membre_service.dart](groupe/groupe_membre_service.dart) - Membres
- [groupe_profil_service.dart](groupe/groupe_profil_service.dart) - Profil enrichi

📖 **Documentation détaillée** : [README.md](groupe/README.md)

### Résumé rapide

| Service | Endpoint | Quand l'utiliser |
|---------|----------|------------------|
| `GroupeService.createGroupe()` | Créer un groupe | Bouton "Créer un groupe" |
| `GroupeService.searchGroupes()` | Rechercher des groupes | Page de recherche |
| `GroupeMembreService.joinGroupe()` | Rejoindre un groupe public | Clic "Rejoindre" |
| `GroupeInvitationService.inviteMembre()` | Inviter quelqu'un | Bouton "Inviter" |
| `GroupeProfilService.updateProfil()` | Modifier le profil du groupe | Page admin du groupe |

---

## 6. Flux d'utilisation complets

### Flux 1 : Découvrir et suivre un utilisateur

```
1. HomePage → Clic "Rechercher" → UserSearchPage
2. Saisir un nom → UserAuthService.searchUsers(query)
3. Résultats affichés → Clic sur un utilisateur
4. UserProfilePage(userId) → UserAuthService.getUserProfile(userId)
5. Profil affiché → Clic "Suivre"
6. SuivreService.suivreUser(userId)
7. Bouton devient "Abonné"
```

### Flux 2 : Publier un post et interagir

```
1. HomePage → Clic FAB "+" → CreatePostPage
2. Rédiger contenu + Ajouter photo
3. PostService.uploadMedia() puis PostService.createPost()
4. Retour à HomePage → Post visible dans le fil
5. Autre utilisateur like → LikeService.likePost(postId)
6. Autre utilisateur commente → CommentService.commentPost()
```

### Flux 3 : Envoyer un message privé

```
1. UserProfilePage → Clic "Message"
2. ConversationService.createOrGetConversation(userId, 'User')
3. Navigation → ConversationPage
4. MessageService.getMessagesByConversation(conversationId)
5. Rédiger message → MessageService.sendMessage()
6. Message envoyé et affiché
```

### Flux 4 : Rejoindre et participer à un groupe

```
1. Recherche de groupes → GroupeService.searchGroupes('flutter')
2. Résultats affichés → Clic sur un groupe
3. GroupeDetailPage → GroupeProfilService.getProfil(groupeId)
4. Si public → Clic "Rejoindre" → GroupeMembreService.joinGroupe()
5. Si privé → Afficher "Groupe privé, contactez un admin"
6. Une fois membre → Accès aux posts du groupe
```

---

## Aide-mémoire rapide

### Authentification
- `login()` = Page de connexion
- `getMyProfile()` = MON profil
- `getUserProfile(id)` = Profil de QUELQU'UN D'AUTRE

### Relations
- `suivreUser()` = Bouton "Suivre"
- `getMySuivis()` = Page "Abonnements"
- `acceptInvitation()` = Accepter une invitation

### Posts
- `createPost()` = Publier
- `getMyFeed()` = Fil d'actualité
- `likePost()` = J'aime
- `commentPost()` = Commenter

### Messages
- `createOrGetConversation()` = Démarrer une conversation
- `sendMessage()` = Envoyer un message
- `getMyConversations()` = Liste des conversations

### Groupes
- `createGroupe()` = Créer
- `joinGroupe()` = Rejoindre (public)
- `inviteMembre()` = Inviter (privé)

---

**✅ Ce guide couvre tous les cas d'utilisation pratiques des services GestAuth !**
