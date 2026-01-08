# 📤 Guide Complet - Upload d'Images vers Cloudflare R2

## 🎯 Vue d'Ensemble

Ce guide montre comment utiliser les nouvelles fonctionnalités d'upload d'images optimisées :
- ✅ Validation des fichiers (type et taille)
- ✅ Barre de progression pendant l'upload
- ✅ Widget d'affichage avec cache
- ✅ Compression avant upload

---

## 📦 Packages Installés

```yaml
# pubspec.yaml
dependencies:
  cached_network_image: ^3.3.1      # Affichage avec cache
  flutter_image_compress: ^2.3.0    # Compression d'images
  path: ^1.9.0                      # Manipulation de chemins
  path_provider: ^2.1.2             # Accès aux répertoires
```

---

## 🔧 Services et Utilitaires Disponibles

### 1. ApiService (Amélioré)
**Fichier**: `lib/services/api_service.dart`

**Nouvelles méthodes**:
- `uploadFileWithValidation()` - Upload avec validation type/taille
- `uploadFileWithProgress()` - Upload avec barre de progression
- `uploadFileComplete()` - Upload avec validation ET progression

### 2. ImageCompressor
**Fichier**: `lib/utils/image_compressor.dart`

**Méthodes disponibles**:
- `compressImage()` - Compression personnalisée
- `compressImageAuto()` - Compression automatique selon taille
- `compressImageLight()` - Compression légère (haute qualité)
- `compressImageMedium()` - Compression moyenne
- `compressImageHeavy()` - Compression forte
- `compressImageThumbnail()` - Miniature

### 3. R2NetworkImage
**Fichier**: `lib/widgets/r2_network_image.dart`

**Widgets disponibles**:
- `R2NetworkImage` - Image avec cache
- `R2AvatarImage` - Avatar circulaire
- `R2ImageGrid` - Grille d'images
- `R2ImageWithAction` - Image avec overlay et action

---

## 💡 Exemples d'Utilisation

### Exemple 1: Upload Simple avec Validation

```dart
import 'package:gestauth_clean/services/api_service.dart';

Future<void> uploadProfileImage(String imagePath) async {
  try {
    // Upload avec validation automatique
    final response = await ApiService.uploadFileWithValidation(
      imagePath,
      '/upload/profile',
      'image',  // Type: 'image', 'video', ou 'audio'
      fieldName: 'file',
      additionalFields: {
        'userId': '123',
        'type': 'profile',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final imageUrl = data['data']['url'];
      print('Image uploadée: $imageUrl');
    }
  } catch (e) {
    // Gestion des erreurs de validation
    print('Erreur: $e');
    // Exemples d'erreurs:
    // - "Extension de fichier non autorisée: .txt"
    // - "Fichier trop volumineux: 15.2MB. Taille maximale: 10MB"
  }
}
```

### Exemple 2: Upload avec Barre de Progression

```dart
import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/api_service.dart';

class ImageUploadWithProgress extends StatefulWidget {
  final String imagePath;

  const ImageUploadWithProgress({required this.imagePath, super.key});

  @override
  State<ImageUploadWithProgress> createState() => _ImageUploadWithProgressState();
}

class _ImageUploadWithProgressState extends State<ImageUploadWithProgress> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final response = await ApiService.uploadFileWithProgress(
        widget.imagePath,
        '/upload/post',
        fieldName: 'file',
        additionalFields: {'type': 'post_image'},
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Upload terminé: ${data['data']['url']}');
      }
    } catch (e) {
      print('Erreur upload: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
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
          child: const Text('Upload Image'),
        ),
      ],
    );
  }
}
```

### Exemple 3: Compression Avant Upload

```dart
import 'package:gestauth_clean/services/api_service.dart';
import 'package:gestauth_clean/utils/image_compressor.dart';

Future<void> uploadImageWithCompression(String imagePath) async {
  try {
    // 1. Compresser l'image automatiquement
    print('Compression de l\'image...');
    final compressedPath = await ImageCompressor.compressImageAuto(imagePath);

    if (compressedPath == null) {
      throw Exception('Échec de la compression');
    }

    // 2. Afficher les statistiques de compression
    final stats = await ImageCompressor.getCompressionStats(
      imagePath,
      compressedPath,
    );
    print('Taille originale: ${stats['original_mb']} MB');
    print('Taille compressée: ${stats['compressed_mb']} MB');
    print('Réduction: ${stats['reduction_percent']}%');

    // 3. Upload du fichier compressé avec progression
    final response = await ApiService.uploadFileComplete(
      compressedPath,
      '/upload/post',
      'image',
      onProgress: (progress) {
        print('Upload: ${(progress * 100).toStringAsFixed(0)}%');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Image uploadée: ${data['data']['url']}');
    }
  } catch (e) {
    print('Erreur: $e');
  }
}
```

### Exemple 4: Compression Personnalisée

```dart
import 'package:gestauth_clean/utils/image_compressor.dart';

// Compression légère (haute qualité)
final lightPath = await ImageCompressor.compressImageLight(imagePath);

// Compression moyenne (équilibrée)
final mediumPath = await ImageCompressor.compressImageMedium(imagePath);

// Compression forte (petite taille)
final heavyPath = await ImageCompressor.compressImageHeavy(imagePath);

// Miniature
final thumbnailPath = await ImageCompressor.compressImageThumbnail(imagePath);

// Compression personnalisée
final customPath = await ImageCompressor.compressImage(
  imagePath,
  quality: 90,       // Qualité 0-100
  maxWidth: 2048,    // Largeur max en pixels
  maxHeight: 2048,   // Hauteur max en pixels
);
```

### Exemple 5: Affichage d'Images avec Cache

```dart
import 'package:flutter/material.dart';
import 'package:gestauth_clean/widgets/r2_network_image.dart';

class PostImageDisplay extends StatelessWidget {
  final String imageUrl;

  const PostImageDisplay({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return R2NetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
```

### Exemple 6: Avatar avec Image R2

```dart
import 'package:gestauth_clean/widgets/r2_network_image.dart';

// Avatar simple
R2AvatarImage(
  imageUrl: 'https://r2.titingre.com/avatars/user123.jpg',
  radius: 30,
)

// Avatar avec couleur de fond personnalisée
R2AvatarImage(
  imageUrl: userAvatarUrl,
  radius: 25,
  backgroundColor: Colors.blue[100],
)
```

### Exemple 7: Grille d'Images

```dart
import 'package:gestauth_clean/widgets/r2_network_image.dart';

R2ImageGrid(
  imageUrls: [
    'https://r2.titingre.com/posts/image1.jpg',
    'https://r2.titingre.com/posts/image2.jpg',
    'https://r2.titingre.com/posts/image3.jpg',
    'https://r2.titingre.com/posts/image4.jpg',
  ],
  crossAxisCount: 2,  // 2 colonnes
  spacing: 8.0,       // Espacement entre images
  aspectRatio: 1.0,   // Ratio 1:1 (carré)
)
```

### Exemple 8: Image avec Action et Overlay

```dart
import 'package:gestauth_clean/widgets/r2_network_image.dart';

R2ImageWithAction(
  imageUrl: postImageUrl,
  width: double.infinity,
  height: 400,
  onTap: () {
    // Ouvrir en plein écran
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImage(imageUrl: postImageUrl),
      ),
    );
  },
  overlayWidget: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.7),
        ],
      ),
    ),
    child: Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Photo de vacances',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ),
)
```

### Exemple 9: Workflow Complet (Post avec Image)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gestauth_clean/services/api_service.dart';
import 'package:gestauth_clean/utils/image_compressor.dart';

class CreatePostWithImage extends StatefulWidget {
  const CreatePostWithImage({super.key});

  @override
  State<CreatePostWithImage> createState() => _CreatePostWithImageState();
}

class _CreatePostWithImageState extends State<CreatePostWithImage> {
  final _picker = ImagePicker();
  String? _selectedImagePath;
  double _uploadProgress = 0.0;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _createPost() async {
    if (_selectedImagePath == null) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Compression de l'image
      final compressedPath = await ImageCompressor.compressImageAuto(
        _selectedImagePath!,
      );

      if (compressedPath == null) {
        throw Exception('Échec de la compression');
      }

      // 2. Upload avec validation et progression
      final response = await ApiService.uploadFileComplete(
        compressedPath,
        '/upload/post',
        'image',
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data']['url'];

        // 3. Créer le post avec l'URL de l'image
        await _createPostWithImageUrl(imageUrl);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post créé avec succès!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _createPostWithImageUrl(String imageUrl) async {
    await ApiService.post('/posts', {
      'content': 'Mon nouveau post avec image!',
      'imageUrl': imageUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImagePath != null)
              Image.file(
                File(_selectedImagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Choisir une image'),
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 8),
                  Text('Upload: ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_selectedImagePath != null && !_isProcessing)
                  ? _createPost
                  : null,
              child: const Text('Créer le Post'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔒 Limites de Validation

### Extensions Autorisées

**Images**:
- `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.bmp`

**Vidéos**:
- `.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`

**Audio**:
- `.mp3`, `.wav`, `.aac`, `.m4a`, `.ogg`

### Taille Maximale
- **10 MB** par fichier

### Modification des Limites

Pour changer les limites, modifiez les constantes dans `api_service.dart`:

```dart
class ApiService {
  // Changer la taille maximale (en bytes)
  static const int maxFileSize = 15 * 1024 * 1024; // 15 MB

  // Ajouter des extensions
  static const List<String> allowedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'
  ];
}
```

---

## ⚙️ Niveaux de Compression

### Compression Automatique (`compressImageAuto`)

| Taille Originale | Compression Appliquée | Qualité | Dimensions Max |
|-----------------|----------------------|---------|----------------|
| < 1 MB | Légère | 95% | 2560x2560 |
| 1-3 MB | Moyenne | 85% | 1920x1920 |
| 3-5 MB | Forte | 70% | 1280x1280 |
| 5-10 MB | Forte | 70% | 1280x1280 |
| > 10 MB | ❌ Erreur | - | - |

### Compression Prédéfinie

| Méthode | Qualité | Dimensions Max | Usage |
|---------|---------|----------------|-------|
| `compressImageLight()` | 95% | 2560x2560 | Photos haute qualité |
| `compressImageMedium()` | 85% | 1920x1920 | Photos standard |
| `compressImageHeavy()` | 70% | 1280x1280 | Réduction maximale |
| `compressImageThumbnail()` | 80% | 400x400 | Miniatures |

---

## 🚀 Bonnes Pratiques

### 1. Toujours Compresser Avant Upload

```dart
// ❌ MAL
await ApiService.uploadFileWithValidation(imagePath, '/upload', 'image');

// ✅ BIEN
final compressedPath = await ImageCompressor.compressImageAuto(imagePath);
await ApiService.uploadFileComplete(compressedPath, '/upload', 'image');
```

### 2. Afficher la Progression pour Gros Fichiers

```dart
// Pour fichiers > 1MB, toujours afficher la progression
if (fileSize > 1024 * 1024) {
  await ApiService.uploadFileWithProgress(
    filePath,
    endpoint,
    onProgress: (progress) => print('$progress%'),
  );
}
```

### 3. Utiliser le Cache pour Affichage

```dart
// ❌ MAL
Image.network(imageUrl)

// ✅ BIEN
R2NetworkImage(imageUrl: imageUrl)
```

### 4. Gestion des Erreurs

```dart
try {
  await ApiService.uploadFileComplete(path, '/upload', 'image');
} on Exception catch (e) {
  if (e.toString().contains('trop volumineux')) {
    // Fichier trop gros
    showDialog(context, 'Fichier trop volumineux (max 10MB)');
  } else if (e.toString().contains('non autorisée')) {
    // Extension invalide
    showDialog(context, 'Format de fichier non supporté');
  } else {
    // Autre erreur
    showDialog(context, 'Erreur d\'upload');
  }
}
```

---

## 📊 Statistiques de Compression

```dart
final stats = await ImageCompressor.getCompressionStats(
  originalPath,
  compressedPath,
);

print('Original: ${stats['original_mb']} MB');
print('Compressé: ${stats['compressed_mb']} MB');
print('Réduction: ${stats['reduction_percent']}%');
print('Ratio: ${stats['size_ratio']}%');

// Exemple de sortie:
// Original: 8.45 MB
// Compressé: 2.13 MB
// Réduction: 74.8%
// Ratio: 25.2%
```

---

## 🎯 Résumé

### Workflow Complet Recommandé

1. **Sélection de l'image** (image_picker)
2. **Compression automatique** (ImageCompressor.compressImageAuto)
3. **Upload avec validation et progression** (ApiService.uploadFileComplete)
4. **Affichage avec cache** (R2NetworkImage)

### Avantages

✅ **Validation automatique** - Empêche les uploads invalides
✅ **Compression intelligente** - Réduit la taille sans perte visible
✅ **Progression temps réel** - Meilleure UX pour l'utilisateur
✅ **Cache automatique** - Chargement instantané au 2ème affichage
✅ **Économie de bande passante** - Fichiers plus petits
✅ **Compatible R2** - Optimisé pour Cloudflare R2

---

## 🔗 Fichiers de Référence

- **ApiService**: [lib/services/api_service.dart](../api_service.dart)
- **ImageCompressor**: [lib/utils/image_compressor.dart](../../utils/image_compressor.dart)
- **R2NetworkImage**: [lib/widgets/r2_network_image.dart](../../widgets/r2_network_image.dart)
- **Dependencies**: [pubspec.yaml](../../../pubspec.yaml)

---

**Système d'upload optimisé et prêt pour la production! 🚀**
