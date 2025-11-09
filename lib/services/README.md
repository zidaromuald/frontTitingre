# 📚 Services API - Guide d'Utilisation

Ce dossier contient les services pour interagir avec votre API NestJS backend.

## 📁 Structure des Services

```
services/
├── api_service.dart          # Service de base pour les appels HTTP
├── auth_service.dart          # Service d'authentification
├── post_service.dart          # Service de gestion des posts
├── exemple_utilisation.dart   # Exemples de code (à ne pas inclure en production)
└── README.md                  # Ce fichier
```

---

## ⚙️ Configuration

### 1. URL de l'API

Modifiez l'URL de base dans `api_service.dart` :

```dart
static const String baseUrl = 'http://localhost:3000'; // Développement local
// static const String baseUrl = 'https://api.votresite.com'; // Production
```

### 2. Packages Requis

Assurez-vous que `pubspec.yaml` contient :

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
```

---

## 🔐 Authentification

### Connexion

```dart
import 'services/auth_service.dart';

final user = await AuthService.login(
  email: 'user@example.com',
  password: 'password123',
);
```

### Inscription

```dart
final user = await AuthService.register(
  nom: 'Doe',
  prenom: 'John',
  email: 'john@example.com',
  password: 'password123',
  telephone: '+226 70 12 34 56',
);
```

### Déconnexion

```dart
await AuthService.logout();
```

---

## 📝 Gestion des Posts

### Logique de Visibilité

| Scénario | `groupe_id` | `societe_id` | `visibility` | Qui Voit? |
|----------|-------------|--------------|--------------|-----------|
| **User - Public** | `null` | `null` | `public` | Tous ses followers |
| **User → Groupe** | `X` | `null` | `groupe` | Membres du groupe |
| **User → Société** | `null` | `X` | `societe` | Membres de la société |
| **Société - Public** | `null` | `null` | `public` | Tous les followers |
| **Société → Groupe** | `X` | `null` | `groupe` | Membres du groupe |

### Créer un Post

#### 1. Post PUBLIC (visible par tous les followers)

```dart
import 'services/post_service.dart';

final post = await PostService.createPost(
  contenu: 'Ceci est mon premier post public !',
  visibility: 'public',
);
```

#### 2. Post dans un GROUPE

```dart
final post = await PostService.createPost(
  contenu: 'Réunion ce soir à 18h !',
  groupeId: 5, // ID du groupe
);
```

#### 3. Post dans une SOCIÉTÉ

```dart
final post = await PostService.createPost(
  contenu: 'Nouvelle politique de congés',
  societeId: 12, // ID de la société
);
```

#### 4. Post avec IMAGE

```dart
import 'services/api_service.dart';

// 1. Uploader l'image
final imageUrl = await ApiService.uploadFile(
  '/path/to/image.jpg',
  'image',
);

// 2. Créer le post
final post = await PostService.createPost(
  contenu: 'Belle photo !',
  images: [imageUrl!],
  visibility: 'public',
);
```

#### 5. Post avec VIDÉO

```dart
final videoUrl = await ApiService.uploadFile(
  '/path/to/video.mp4',
  'video',
);

final post = await PostService.createPost(
  contenu: 'Vidéo de démonstration',
  videos: [videoUrl!],
  groupeId: 3,
);
```

#### 6. Post avec AUDIO (vocal)

```dart
final audioUrl = await ApiService.uploadFile(
  '/path/to/audio.mp3',
  'audio',
);

final post = await PostService.createPost(
  contenu: 'Message vocal',
  audios: [audioUrl!],
);
```

### Récupérer des Posts

#### Feed Public

```dart
final posts = await PostService.getPublicFeed(
  limit: 20,
  offset: 0,
  onlyWithMedia: false,
);
```

#### Posts d'un Groupe

```dart
final posts = await PostService.getPostsByGroupe(5);
```

#### Posts d'une Société

```dart
final posts = await PostService.getPostsBySociete(12);
```

#### Posts d'un Auteur

```dart
final posts = await PostService.getPostsByAuthor(
  authorId: 1,
  authorType: 'User', // ou 'Societe'
  includeGroupPosts: true,
);
```

#### Recherche de Posts

```dart
final posts = await PostService.searchPosts(
  query: 'réunion',
  groupeId: 5,
  hasMedia: true,
);
```

### Actions sur les Posts

#### Mettre à jour

```dart
final updatedPost = await PostService.updatePost(
  42,
  {'contenu': 'Contenu modifié'},
);
```

#### Supprimer

```dart
await PostService.deletePost(42);
```

#### Épingler

```dart
await PostService.togglePin(42);
```

#### Partager

```dart
await PostService.sharePost(42);
```

---

## 🎯 Intégration dans un Widget Flutter

### Exemple : Créer un Post

```dart
import 'package:flutter/material.dart';
import 'services/post_service.dart';
import 'services/api_service.dart';

class CreerPostPage extends StatefulWidget {
  @override
  _CreerPostPageState createState() => _CreerPostPageState();
}

class _CreerPostPageState extends State<CreerPostPage> {
  final TextEditingController _textController = TextEditingController();
  String destinataire = 'public'; // 'public', 'groupe', 'societe'
  int? selectedGroupeId;
  int? selectedSocieteId;
  List<String> uploadedImages = [];
  bool isLoading = false;

  Future<void> _publierPost() async {
    // Validation
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez saisir du texte')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await PostService.createPost(
        contenu: _textController.text,
        groupeId: destinataire == 'groupe' ? selectedGroupeId : null,
        societeId: destinataire == 'societe' ? selectedSocieteId : null,
        visibility: destinataire,
        images: uploadedImages.isNotEmpty ? uploadedImages : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post publié avec succès !')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Créer un post')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(hintText: 'Quoi de neuf ?'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _publierPost,
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Exemple : Afficher les Posts

```dart
import 'package:flutter/material.dart';
import 'services/post_service.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final fetchedPosts = await PostService.getPublicFeed(limit: 20);
      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          child: ListTile(
            title: Text(post.contenu),
            subtitle: Text(
              '${post.postedByType} #${post.postedById} - ${post.createdAt}',
            ),
          ),
        );
      },
    );
  }
}
```

---

## 🚨 Gestion des Erreurs

Tous les services lancent des **Exceptions** en cas d'erreur. Utilisez **try-catch** :

```dart
try {
  final post = await PostService.createPost(contenu: 'Test');
  print('Succès: ${post.id}');
} catch (e) {
  print('Erreur: $e');
  // Afficher un message à l'utilisateur
}
```

---

## 📋 Checklist Backend NestJS

Assurez-vous que votre backend a ces routes :

### Authentification
- [x] `POST /auth/login`
- [x] `POST /auth/register`
- [x] `GET /auth/me`

### Posts
- [x] `POST /posts` - Créer un post
- [x] `GET /posts/:id` - Récupérer un post
- [x] `PUT /posts/:id` - Mettre à jour
- [x] `DELETE /posts/:id` - Supprimer
- [x] `GET /posts/feed/public` - Feed public
- [x] `GET /posts/groupe/:id` - Posts d'un groupe
- [ ] `GET /posts/societe/:id` - **À CRÉER** Posts d'une société
- [x] `GET /posts/author/:type/:id` - Posts d'un auteur
- [x] `GET /posts/search/query` - Recherche
- [x] `PUT /posts/:id/pin` - Épingler
- [x] `POST /posts/:id/share` - Partager
- [x] `GET /posts/trending/top` - Tendances
- [ ] `POST /posts/upload` - **À CRÉER** Upload de médias

---

## ✅ TODO Backend

### Routes Manquantes

Ajoutez ces routes dans votre `PostController` :

```typescript
// GET /posts/societe/:id
@Get('societe/:id')
async getBySociete(
  @Param('id', ParseIntPipe) id: number,
  @Query('visibility') visibility?: PostVisibility,
) {
  const posts = await this.postService.getPostsBySociete(id, visibility);
  return {
    success: true,
    data: posts.map((post) => this.postMapper.toSimpleData(post)),
  };
}

// POST /posts/upload
@Post('upload')
@UseInterceptors(FileInterceptor('file'))
async uploadMedia(@UploadedFile() file: Express.Multer.File) {
  const fileUrl = await this.postService.saveMediaFile(file);
  return { success: true, data: { url: fileUrl } };
}
```

---

## 📞 Support

Pour toute question, consultez :
- `exemple_utilisation.dart` - Exemples de code
- Documentation API NestJS backend
- Documentation Flutter HTTP : https://pub.dev/packages/http

---

**Auteur** : Service généré pour le projet Titingre
**Version** : 1.0.0
**Date** : 2025
