# 📤 MediaService Amélioré - Guide Complet

## 🎯 Architecture Correcte

### Séparation des Responsabilités

✅ **ApiService** ([api_service.dart](../api_service.dart))
- Méthodes HTTP de base: `get()`, `post()`, `put()`, `delete()`
- Gestion du token JWT
- Headers HTTP
- **NE gère PAS les uploads de médias**

✅ **MediaService** ([media_service.dart](../media_service.dart))
- **Service dédié pour les uploads de médias**
- Validation des fichiers (type + taille)
- Progression en temps réel
- Gestion des différents types de médias
- Compatible avec Cloudflare R2

---

## 📋 Fonctionnalités de MediaService

### 1. ✅ Validation Automatique

**Types de fichiers validés**:
- **Images**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.bmp`
- **Vidéos**: `.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`
- **Audio**: `.mp3`, `.wav`, `.aac`, `.m4a`, `.ogg`
- **Documents**: `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx`, `.txt`

**Taille maximale**: 10 MB par fichier

**Validation automatique** sur chaque upload:
```dart
try {
  await MediaService.uploadImage(file);
} catch (e) {
  // Erreur: "Extension de fichier non autorisée: .txt"
  // Erreur: "Fichier trop volumineux: 15.2MB. Taille maximale: 10MB"
}
```

### 2. ✅ Progression en Temps Réel

Chaque méthode d'upload supporte un callback `onProgress`:

```dart
await MediaService.uploadImage(
  file,
  onProgress: (progress) {
    print('Upload: ${(progress * 100).toInt()}%');
    // progress = 0.0 à 1.0
  },
);
```

### 3. ✅ Méthodes par Type de Média

```dart
// Upload d'image
final response = await MediaService.uploadImage(imageFile);

// Upload de vidéo
final response = await MediaService.uploadVideo(videoFile);

// Upload d'audio
final response = await MediaService.uploadAudio(audioFile);

// Upload de document
final response = await MediaService.uploadDocument(pdfFile);

// Upload automatique (détection du type)
final response = await MediaService.uploadAuto(file);
```

---

## 💡 Exemples d'Utilisation

### Exemple 1: Upload Simple avec Validation

```dart
import 'dart:io';
import 'package:gestauth_clean/services/media_service.dart';

Future<void> uploadProfileImage(File imageFile) async {
  try {
    final response = await MediaService.uploadImage(imageFile);

    print('Image uploadée: ${response.url}');
    print('Taille: ${response.size} bytes');
    print('Type MIME: ${response.mimetype}');
  } catch (e) {
    print('Erreur: $e');
  }
}
```

### Exemple 2: Upload avec Barre de Progression

```dart
import 'package:flutter/material.dart';

class ImageUploadWidget extends StatefulWidget {
  final File imageFile;

  const ImageUploadWidget({required this.imageFile, super.key});

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String? _uploadedUrl;

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final response = await MediaService.uploadImage(
        widget.imageFile,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      setState(() {
        _uploadedUrl = response.url;
        _isUploading = false;
      });

      print('Upload réussi: $_uploadedUrl');
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isUploading)
          Column(
            children: [
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ElevatedButton(
          onPressed: _isUploading ? null : _uploadImage,
          child: const Text('Upload'),
        ),
        if (_uploadedUrl != null)
          Text('URL: $_uploadedUrl'),
      ],
    );
  }
}
```

### Exemple 3: Upload Multiple en Parallèle

```dart
Future<void> uploadMultipleImages(List<File> images) async {
  try {
    // Upload de toutes les images en parallèle
    final urls = await MediaService.uploadImages(images);

    print('${urls.length} images uploadées:');
    for (final url in urls) {
      print('- $url');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}
```

### Exemple 4: Upload avec Compression

Utilisez `ImageCompressor` avant d'uploader:

```dart
import 'package:gestauth_clean/utils/image_compressor.dart';

Future<String> uploadImageWithCompression(File imageFile) async {
  try {
    // 1. Compresser l'image
    final compressedPath = await ImageCompressor.compressImageAuto(
      imageFile.path,
    );

    if (compressedPath == null) {
      throw Exception('Échec de la compression');
    }

    // 2. Upload avec progression
    final response = await MediaService.uploadImage(
      File(compressedPath),
      onProgress: (progress) {
        print('Upload: ${(progress * 100).toInt()}%');
      },
    );

    return response.url;
  } catch (e) {
    throw Exception('Erreur: $e');
  }
}
```

### Exemple 5: Workflow Complet (Post avec Image)

```dart
import 'package:gestauth_clean/services/media_service.dart';
import 'package:gestauth_clean/services/api_service.dart';
import 'package:gestauth_clean/utils/image_compressor.dart';

Future<void> createPostWithImage(File imageFile, String content) async {
  try {
    // 1. Compresser l'image
    final compressedPath = await ImageCompressor.compressImageMedium(
      imageFile.path,
    );

    // 2. Upload de l'image compressée
    final response = await MediaService.uploadImage(
      File(compressedPath!),
      onProgress: (progress) {
        print('Upload: ${(progress * 100).toInt()}%');
      },
    );

    // 3. Créer le post avec l'URL de l'image
    final postResponse = await ApiService.post('/posts', {
      'content': content,
      'imageUrl': response.url,
      'imageSize': response.size,
      'imageMimetype': response.mimetype,
    });

    print('Post créé avec succès!');
  } catch (e) {
    print('Erreur: $e');
  }
}
```

### Exemple 6: Upload Automatique (Détection du Type)

```dart
Future<void> uploadAnyFile(File file) async {
  try {
    // MediaService détecte automatiquement le type (image/video/audio/document)
    final response = await MediaService.uploadAuto(file);

    print('Fichier uploadé: ${response.url}');
    print('Type détecté: ${response.type}');
  } catch (e) {
    print('Erreur: $e');
  }
}
```

---

## 📊 Réponse d'Upload

Chaque upload retourne un `MediaUploadResponse`:

```dart
class MediaUploadResponse {
  final String url;         // URL Cloudflare R2
  final String filename;    // Nom du fichier
  final int size;          // Taille en bytes
  final String mimetype;   // Type MIME (image/jpeg, video/mp4, etc.)
  final String type;       // Type (image, video, audio, document)
}
```

Exemple:
```json
{
  "url": "https://r2.titingre.com/uploads/image-123.jpg",
  "filename": "image-123.jpg",
  "size": 2048576,
  "mimetype": "image/jpeg",
  "type": "image"
}
```

---

## 🔒 Endpoints Backend

MediaService communique avec les endpoints NestJS suivants:

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `uploadImage()` | `POST /media/upload/image` | Upload d'image |
| `uploadVideo()` | `POST /media/upload/video` | Upload de vidéo |
| `uploadAudio()` | `POST /media/upload/audio` | Upload d'audio |
| `uploadDocument()` | `POST /media/upload/document` | Upload de document |
| `uploadAuto()` | `POST /media/upload/{type}` | Type détecté auto |

**Format de requête**: `multipart/form-data`
**Champ fichier**: `file`
**Authentification**: JWT (automatique via `Authorization: Bearer <token>`)

---

## 🎯 Workflow Recommandé

```
1. Sélectionner le fichier (image_picker)
   ↓
2. Compression (optionnelle mais recommandée)
   ↓
3. Upload avec MediaService
   → Validation automatique (type + taille)
   → Progression en temps réel
   → Upload vers Cloudflare R2
   ↓
4. Récupérer l'URL
   ↓
5. Utiliser l'URL dans votre application
   → Créer un post
   → Mettre à jour un profil
   → Envoyer un message
   ↓
6. Afficher avec R2NetworkImage (cache automatique)
```

---

## ⚠️ Gestion des Erreurs

MediaService lance des exceptions détaillées:

```dart
try {
  await MediaService.uploadImage(file);
} catch (e) {
  if (e.toString().contains('Extension de fichier non autorisée')) {
    // Mauvais format de fichier
    showError('Format non supporté');
  } else if (e.toString().contains('trop volumineux')) {
    // Fichier trop gros
    showError('Fichier trop volumineux (max 10MB)');
  } else if (e.toString().contains('Non authentifié')) {
    // Token expiré ou manquant
    redirectToLogin();
  } else {
    // Autre erreur
    showError('Erreur d\'upload');
  }
}
```

---

## ⚙️ Configuration

### Modifier la Taille Maximale

Éditez [media_service.dart](../media_service.dart):

```dart
class MediaService {
  // Changer la taille max (en bytes)
  static const int maxFileSize = 15 * 1024 * 1024; // 15 MB au lieu de 10 MB
}
```

### Ajouter des Extensions

```dart
class MediaService {
  // Ajouter .svg aux images
  static const List<String> allowedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'
  ];
}
```

---

## 🚀 Intégration avec Compression

Workflow optimal avec compression:

```dart
import 'package:gestauth_clean/services/media_service.dart';
import 'package:gestauth_clean/utils/image_compressor.dart';

Future<String> uploadImageOptimized(File imageFile) async {
  // 1. Afficher stats avant compression
  final originalSize = await ImageCompressor.getFileSizeMB(imageFile.path);
  print('Taille originale: ${originalSize}MB');

  // 2. Compresser automatiquement selon la taille
  final compressedPath = await ImageCompressor.compressImageAuto(imageFile.path);

  if (compressedPath != null) {
    // 3. Afficher stats de compression
    final stats = await ImageCompressor.getCompressionStats(
      imageFile.path,
      compressedPath,
    );
    print('Compression: ${stats['reduction_percent']}%');
    print('Nouvelle taille: ${stats['compressed_mb']}MB');

    // 4. Upload du fichier compressé
    final response = await MediaService.uploadImage(
      File(compressedPath),
      onProgress: (progress) => print('${(progress * 100).toInt()}%'),
    );

    return response.url;
  } else {
    // Fallback: upload sans compression
    final response = await MediaService.uploadImage(imageFile);
    return response.url;
  }
}
```

---

## 📦 Fichiers Liés

### Services
- **[media_service.dart](../media_service.dart)** - Service principal d'upload
- **[api_service.dart](../api_service.dart)** - Service HTTP de base

### Utilitaires
- **[image_compressor.dart](../../utils/image_compressor.dart)** - Compression d'images

### Widgets
- **[r2_network_image.dart](../../widgets/r2_network_image.dart)** - Affichage avec cache

### Documentation
- **[EXEMPLE_UPLOAD_COMPLET.md](./EXEMPLE_UPLOAD_COMPLET.md)** - Exemples détaillés
- **[README.md](./README.md)** - Vue d'ensemble

---

## ✅ Résumé

### Architecture Finale

```
┌─────────────────┐
│   ApiService    │  → Appels HTTP de base (GET, POST, PUT, DELETE)
└─────────────────┘

┌─────────────────┐
│  MediaService   │  → Upload de médias (validation + progression)
└─────────────────┘  → Cloudflare R2

┌─────────────────┐
│ImageCompressor  │  → Compression avant upload
└─────────────────┘

┌─────────────────┐
│R2NetworkImage   │  → Affichage avec cache
└─────────────────┘
```

### Avantages

✅ **Séparation des responsabilités** - Chaque service a un rôle clair
✅ **Validation automatique** - Pas d'upload invalide
✅ **Progression visible** - Meilleure UX
✅ **Type-safe** - `MediaType` enum
✅ **Réutilisable** - Méthodes par type de média
✅ **Évolutif** - Facile d'ajouter de nouveaux types

---

**MediaService est prêt pour la production! 🚀**
