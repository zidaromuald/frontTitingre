/// ========================================
/// EXEMPLES D'UTILISATION DES SERVICES
/// ========================================
///
/// Ce fichier contient des exemples de comment utiliser
/// les services API dans votre application Flutter.
///
/// NE PAS INCLURE CE FICHIER DANS VOTRE BUILD FINAL.
/// ========================================

import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';

import 'posts/post_service.dart';
import 'AuthUS/auth_base_service.dart';
import 'api_service.dart';

/// ========================================
/// 1. AUTHENTIFICATION
/// ========================================

void exempleLogin() async {
  try {
    final user = await UserAuthService.login(
      identifiant: 'user@example.com',
      password: 'password123',
    );

    print('Connexion réussie: ${user.nom} ${user.prenom}');
  } catch (e) {
    print('Erreur de connexion: $e');
  }
}

void exempleRegister() async {
  try {
    final user = await UserAuthService.register(
      nom: 'Doe',
      prenom: 'John',
      email: 'john.doe@example.com',
      password: 'password123',
      numero: '+226 70 12 34 56',
    );

    print('Inscription réussie: ${user.email}');
  } catch (e) {
    print('Erreur d\'inscription: $e');
  }
}

/// ========================================
/// 2. CRÉATION DE POSTS
/// ========================================

/// Exemple 1: Post PUBLIC (visible par tous les followers)
void exemplePostPublic() async {
  try {
    final post = await PostService.createPost(
      contenu: 'Ceci est mon premier post public !',
      visibility: 'public',
    );

    print('Post créé avec succès: ${post.id}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Exemple 2: Post dans un GROUPE
void exemplePostGroupe() async {
  try {
    final post = await PostService.createPost(
      contenu: 'Réunion ce soir à 18h !',
      groupeId: 5, // ID du groupe
      visibility: 'groupe', // Optionnel, sera auto-détecté
    );

    print('Post créé dans le groupe: ${post.id}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Exemple 3: Post dans une SOCIÉTÉ
void exemplePostSociete() async {
  try {
    final post = await PostService.createPost(
      contenu: 'Nouvelle politique de congés',
      societeId: 12, // ID de la société
      visibility: 'societe', // Optionnel, sera auto-détecté
    );

    print('Post créé dans la société: ${post.id}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Exemple 4: Post avec IMAGE
void exemplePostAvecImage() async {
  try {
    // D'abord, uploader l'image
    final imageUrl = await ApiService.uploadFile('/path/to/image.jpg', 'image');

    // Ensuite, créer le post avec l'URL de l'image
    final post = await PostService.createPost(
      contenu: 'Regardez cette belle photo !',
      images: [imageUrl!],
      visibility: 'public',
    );

    print('Post avec image créé: ${post.id}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Exemple 5: Post avec VIDÉO
void exemplePostAvecVideo() async {
  try {
    // Uploader la vidéo
    final videoUrl = await ApiService.uploadFile('/path/to/video.mp4', 'video');

    // Créer le post
    final post = await PostService.createPost(
      contenu: 'Nouvelle vidéo de démonstration',
      videos: [videoUrl!],
      groupeId: 3,
    );

    print('Post avec vidéo créé: ${post.id}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Exemple 6: Post AUDIO (vocal)
void exemplePostAvecAudio() async {
  try {
    // Uploader l'audio
    final audioUrl = await ApiService.uploadFile('/path/to/audio.mp3', 'audio');

    // Créer le post
    final post = await PostService.createPost(
      contenu: 'Message vocal important',
      audios: [audioUrl!],
      societeId: 7,
    );

    print('Post audio créé: ${post.id}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// ========================================
/// 3. RÉCUPÉRATION DE POSTS
/// ========================================

/// Récupérer le feed public
void exempleGetFeedPublic() async {
  try {
    final posts = await PostService.getPublicFeed(
      limit: 20,
      offset: 0,
      onlyWithMedia: false,
    );

    print('${posts.length} posts récupérés');
    for (var post in posts) {
      print('- ${post.contenu.substring(0, 30)}...');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Récupérer les posts d'un groupe
void exempleGetPostsGroupe() async {
  try {
    final posts = await PostService.getPostsByGroupe(5);

    print('Posts du groupe 5: ${posts.length}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Récupérer les posts d'une société
void exempleGetPostsSociete() async {
  try {
    final posts = await PostService.getPostsBySociete(12);

    print('Posts de la société 12: ${posts.length}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Rechercher des posts
void exempleRechercherPosts() async {
  try {
    final posts = await PostService.searchPosts(
      query: 'réunion',
      groupeId: 5,
      hasMedia: true,
    );

    print('Résultats: ${posts.length} posts');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// ========================================
/// 4. ACTIONS SUR LES POSTS
/// ========================================

/// Mettre à jour un post
void exempleUpdatePost() async {
  try {
    final updatedPost = await PostService.updatePost(
      42, // ID du post
      {'contenu': 'Contenu modifié'},
    );

    print('Post mis à jour: ${updatedPost.id}');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Supprimer un post
void exempleDeletePost() async {
  try {
    await PostService.deletePost(42);
    print('Post supprimé');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Épingler un post
void exempleTogglePin() async {
  try {
    await PostService.togglePin(42);
    print('Post épinglé/désépinglé');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// Partager un post
void exempleSharePost() async {
  try {
    await PostService.sharePost(42);
    print('Post partagé');
  } catch (e) {
    print('Erreur: $e');
  }
}

/// ========================================
/// 5. EXEMPLE COMPLET DANS UN WIDGET
/// ========================================

/*
import 'package:flutter/material.dart';
import 'services/post_service.dart';

class ExemplePageCreerPost extends StatefulWidget {
  @override
  _ExemplePageCreerPostState createState() => _ExemplePageCreerPostState();
}

class _ExemplePageCreerPostState extends State<ExemplePageCreerPost> {
  final TextEditingController _textController = TextEditingController();
  String destinataire = 'public';
  int? selectedGroupeId;
  int? selectedSocieteId;
  List<String> uploadedImages = [];
  bool isLoading = false;

  Future<void> _publierPost() async {
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
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Créer un post')),
      body: Column(
        children: [
          TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: 'Quoi de neuf ?'),
          ),
          // ... Reste de l'UI
          ElevatedButton(
            onPressed: isLoading ? null : _publierPost,
            child: isLoading
                ? CircularProgressIndicator()
                : Text('Publier'),
          ),
        ],
      ),
    );
  }
}
*/
