# Comment utiliser MediaService avec PostService

## Architecture

```
MediaService (séparé)
    ↓
    Upload fichiers → Retourne URLs
    ↓
PostService
    ↓
    Crée post avec les URLs
```

## Exemple 1 : Créer un post avec images

```dart
import 'dart:io';
import 'package:gestauth_clean/services/media_service.dart';
import 'package:gestauth_clean/services/post_service.dart';

Future<void> createPostWithImages() async {
  try {
    // 1. Sélectionner les fichiers images
    final imageFiles = [
      File('/path/to/image1.jpg'),
      File('/path/to/image2.png'),
    ];

    // 2. Uploader les images via MediaService
    final imageUrls = await MediaService.uploadImages(imageFiles);

    // 3. Créer le post avec les URLs des images
    final post = await PostService.createPost(
      contenu: 'Mon premier post avec des images !',
      images: imageUrls, // ['https://api.com/uploads/image-123.jpg', ...]
      visibility: 'public',
    );

    print('Post créé avec succès : ${post.id}');
  } catch (e) {
    print('Erreur : $e');
  }
}
```

## Exemple 2 : Post avec vidéo et images

```dart
Future<void> createPostWithMixedMedia() async {
  try {
    // 1. Uploader la vidéo
    final videoFile = File('/path/to/video.mp4');
    final videoResponse = await MediaService.uploadVideo(videoFile);

    // 2. Uploader les images
    final imageFiles = [
      File('/path/to/thumbnail.jpg'),
    ];
    final imageUrls = await MediaService.uploadImages(imageFiles);

    // 3. Créer le post
    final post = await PostService.createPost(
      contenu: 'Regardez ma vidéo !',
      videos: [videoResponse.url],
      images: imageUrls,
      visibility: 'public',
    );

    print('Post créé avec vidéo et images');
  } catch (e) {
    print('Erreur : $e');
  }
}
```

## Exemple 3 : Upload automatique (détection de type)

```dart
Future<void> createPostWithAutoDetect() async {
  try {
    // 1. Fichiers mixtes
    final files = [
      File('/path/to/photo.jpg'),    // Détecté comme image
      File('/path/to/song.mp3'),     // Détecté comme audio
      File('/path/to/document.pdf'), // Détecté comme document
    ];

    // 2. Upload avec détection automatique
    final responses = await MediaService.uploadMultiple(files);

    // 3. Séparer par type
    final imageUrls = responses
        .where((r) => r.type == 'image')
        .map((r) => r.url)
        .toList();

    final audioUrls = responses
        .where((r) => r.type == 'audio')
        .map((r) => r.url)
        .toList();

    // 4. Créer le post
    final post = await PostService.createPost(
      contenu: 'Post avec plusieurs types de fichiers',
      images: imageUrls,
      audios: audioUrls,
    );
  } catch (e) {
    print('Erreur : $e');
  }
}
```

## Exemple 4 : Upload dans un groupe avec loader

```dart
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  bool _isUploading = false;
  List<File> _selectedImages = [];

  Future<void> _publishPost() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Upload images
      final imageUrls = await MediaService.uploadImages(_selectedImages);

      // 2. Créer post
      final post = await PostService.createPost(
        contenu: _contentController.text,
        images: imageUrls,
        groupeId: widget.groupeId, // Post dans un groupe
        visibility: 'groupe',
      );

      // 3. Succès
      Navigator.pop(context, post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post publié avec succès')),
      );
    } catch (e) {
      // 4. Erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un post'),
        actions: [
          if (_isUploading)
            Center(child: CircularProgressIndicator())
          else
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _publishPost,
            ),
        ],
      ),
      body: Column(
        children: [
          TextField(controller: _contentController),
          // ... UI pour sélectionner images
        ],
      ),
    );
  }
}
```

## Exemple 5 : Upload avec progression

```dart
class MediaServiceWithProgress {
  static Future<List<String>> uploadImagesWithProgress(
    List<File> images,
    Function(double progress) onProgress,
  ) async {
    final urls = <String>[];

    for (var i = 0; i < images.length; i++) {
      final response = await MediaService.uploadImage(images[i]);
      urls.add(response.url);

      // Notifier la progression (0.0 à 1.0)
      onProgress((i + 1) / images.length);
    }

    return urls;
  }
}

// Usage
await MediaServiceWithProgress.uploadImagesWithProgress(
  selectedImages,
  (progress) {
    setState(() {
      _uploadProgress = progress;
    });
  },
);
```

## Résumé : Séparation des responsabilités

### MediaService (lib/services/media_service.dart)
- ✅ Upload fichiers
- ✅ Validation types MIME
- ✅ Retourne URLs + métadonnées
- ✅ Réutilisable partout (posts, profils, messages, etc.)

### PostService (lib/services/post_service.dart)
- ✅ Gestion logique métier des posts
- ✅ Accepte des URLs de médias déjà uploadés
- ✅ Ne s'occupe PAS de l'upload

## Routes Backend correspondantes

```
POST /media/upload/image    → MediaService.uploadImage()
POST /media/upload/video    → MediaService.uploadVideo()
POST /media/upload/audio    → MediaService.uploadAudio()
POST /media/upload/document → MediaService.uploadDocument()

POST /posts                 → PostService.createPost() (avec URLs)
GET  /posts/:id             → PostService.getPostById()
GET  /posts/feed/public     → PostService.getPublicFeed()
```

## Avantages de cette architecture

1. **Réutilisabilité** : MediaService peut être utilisé pour :
   - Posts
   - Photos de profil
   - Logos de société
   - Documents de groupe
   - Messages avec pièces jointes

2. **Testabilité** : Tester l'upload séparément du post

3. **Performance** : Upload en parallèle de plusieurs fichiers

4. **Maintenance** : Changer la logique d'upload sans toucher aux posts
