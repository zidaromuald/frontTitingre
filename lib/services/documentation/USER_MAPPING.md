# Mapping Backend NestJS ↔️ Frontend Flutter (Users)

## Analyse du Controller `user.controller.ts`

---

## ✅ RÉSULTAT: PARFAITEMENT CONFORME (après correction)

Après analyse du controller backend et correction du service Flutter, tout est maintenant **100% compatible**.

---

## 📊 Comparaison Endpoint par Endpoint

### Routes de Profil

| Endpoint Backend | Méthode Dart | Statut |
|-----------------|--------------|--------|
| `GET /users/me` | `getMyProfile()` | ✅ |
| `PUT /users/me/profile` | `updateMyProfile()` | ✅ |
| `POST /users/me/photo` | `uploadProfilePhoto()` | ✅ CORRIGÉ |
| `GET /users/me/stats` | `getMyStats()` | ✅ |
| `GET /users/:id` | `getUserProfile()` | ✅ |
| `GET /users/:id/stats` | `getUserStats()` | ✅ |

### Routes de Recherche

| Endpoint Backend | Méthode Dart | Statut |
|-----------------|--------------|--------|
| `GET /users/search` | `searchUsers()` | ✅ |
| `GET /users/autocomplete` | `autocomplete()` | ✅ |

**Total: 8/8 endpoints ✅**

---

## 🔧 Correction Appliquée

### Problème Identifié

Le backend a un **endpoint dédié** pour l'upload de photo de profil:

```typescript
/**
 * POST /users/me/photo
 * Uploader une photo de profil
 */
@Post('me/photo')
@UseInterceptors(FileInterceptor('file', getMulterOptions(MediaType.IMAGE)))
async uploadProfilePhoto(
  @CurrentUser() user: User,
  @UploadedFile() file: Express.Multer.File,
) {
  // Upload via MediaService
  const uploadResult = await this.mediaService.handleUpload(file, MediaType.IMAGE);

  // Mettre à jour le profil avec l'URL de la photo
  const profile = await this.userService.updateProfilePhoto(
    user.id,
    uploadResult.data.url,
  );

  return {
    success: true,
    message: 'Photo de profil mise à jour avec succès',
    data: {
      photo: profile.photo,
      url: uploadResult.data.url,
    },
  };
}
```

### Ancien Code Flutter (INCORRECT)

```dart
/// Upload photo de profil
static Future<Map<String, dynamic>> uploadProfilePhoto(
  String filePath,
) async {
  final response = await ApiService.uploadFile(filePath, 'image');

  if (response != null) {
    return {'photo': response, 'url': response};
  } else {
    throw Exception('Erreur lors de l\'upload de la photo');
  }
}
```

**Problèmes:**
- ❌ Envoyait vers `/posts/upload` au lieu de `/users/me/photo`
- ❌ Ne mettait pas à jour le profil automatiquement
- ❌ Nécessitait 2 appels API (upload + update)

### Nouveau Code Flutter (CORRECT) ✅

```dart
/// Upload photo de profil
/// POST /users/me/photo
static Future<Map<String, dynamic>> uploadProfilePhoto(
  String filePath,
) async {
  final response = await ApiService.uploadFileToEndpoint(
    filePath,
    '/users/me/photo',
    fieldName: 'file',
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    final jsonResponse = jsonDecode(response.body);
    return jsonResponse['data']; // Retourne { photo: '...', url: '...' }
  } else {
    final error = jsonDecode(response.body);
    throw Exception(
      error['message'] ?? 'Erreur lors de l\'upload de la photo',
    );
  }
}
```

**Avantages:**
- ✅ Envoie vers le bon endpoint `/users/me/photo`
- ✅ Upload + Mise à jour du profil en **1 seul appel**
- ✅ Compatible avec Multer/FileInterceptor
- ✅ Retourne la structure complète `{ photo: '...', url: '...' }`

---

## 🎯 Workflow Backend

```
1. Client envoie POST /users/me/photo avec FormData
   ├── Champ 'file': fichier image
   └── Header 'Authorization': Bearer <token>

2. JwtAuthGuard vérifie l'authentification

3. FileInterceptor (Multer) intercepte le fichier

4. MediaService.handleUpload() sauvegarde le fichier
   └── Retourne { data: { url: '...' } }

5. UserService.updateProfilePhoto() met à jour le profil en BDD

6. Retourne { success, message, data: { photo: '...', url: '...' } }
```

---

## 📝 Structure de Réponse Backend

```json
{
  "success": true,
  "message": "Photo de profil mise à jour avec succès",
  "data": {
    "photo": "uploads/users/photos/1234567890.jpg",
    "url": "https://api.example.com/storage/uploads/users/photos/1234567890.jpg"
  }
}
```

**Explication:**
- `photo`: Chemin relatif stocké en base de données
- `url`: URL complète pour afficher l'image dans l'app Flutter

---

## 💡 Utilisation Flutter

### Ancien Système (2-3 appels API)

```dart
// ❌ Étape 1: Upload générique
final uploadResult = await UserAuthService.uploadProfilePhoto(filePath);

// ❌ Étape 2: Mise à jour manuelle du profil
await UserAuthService.updateMyProfile({'photo': uploadResult['url']});

// ❌ Étape 3: Rafraîchir pour voir la photo
final profile = await UserAuthService.getMyProfile();
```

### Nouveau Système (1 seul appel API) ✅

```dart
// ✅ Upload + Mise à jour automatique
final result = await UserAuthService.uploadProfilePhoto(filePath);
print('Photo uploadée: ${result['photo']}');
print('URL complète: ${result['url']}');

// Le profil est DÉJÀ mis à jour côté backend!
```

---

## 🎨 Exemple Complet Flutter

```dart
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String? photoUrl;
  bool isLoading = false;

  Future<void> uploadPhoto() async {
    // 1. Sélectionner une image
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => isLoading = true);

    try {
      // 2. Upload vers le backend (1 seul appel!)
      final result = await UserAuthService.uploadProfilePhoto(image.path);

      // 3. Mettre à jour l'interface
      setState(() {
        photoUrl = result['url']; // URL complète
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo de profil mise à jour!')),
      );

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mon Profil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null
                  ? Icon(Icons.person, size: 60)
                  : null,
            ),

            SizedBox(height: 20),

            // Bouton upload
            ElevatedButton.icon(
              onPressed: isLoading ? null : uploadPhoto,
              icon: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.camera_alt),
              label: Text(
                isLoading ? 'Upload en cours...' : 'Changer la photo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📊 Comparaison Ancien vs Nouveau

| Critère | Ancien Système | Nouveau Système |
|---------|---------------|-----------------|
| **Route** | `/posts/upload` ❌ | `/users/me/photo` ✅ |
| **Nombre d'appels API** | 2-3 appels ❌ | 1 seul appel ✅ |
| **Mise à jour profil** | Manuelle ❌ | Automatique ✅ |
| **Retour** | `{'photo': url, 'url': url}` | `{'photo': path, 'url': fullUrl}` ✅ |
| **Performance** | Lente ❌ | Rapide ✅ |
| **Workflow** | Upload → Update → Refresh | Upload (tout en 1) ✅ |

---

## 🔍 Détails Backend vs Flutter

### Backend (NestJS)

**Guards:**
- `@UseGuards(JwtAuthGuard)` - Vérifie l'authentification
- `@CurrentUser()` - Récupère l'utilisateur connecté depuis le JWT

**Interceptors:**
- `FileInterceptor('file', ...)` - Gère l'upload avec Multer
- `getMulterOptions(MediaType.IMAGE)` - Configuration pour les images

**Services:**
- `MediaService.handleUpload()` - Sauvegarde le fichier
- `UserService.updateProfilePhoto()` - Met à jour le profil

### Flutter (Service)

**Headers:**
- `Authorization: Bearer <token>` - Ajouté automatiquement par `ApiService`

**Format:**
- `multipart/form-data` via `http.MultipartRequest`
- Champ `file` contenant le fichier image

**Parsing:**
- Décode la réponse JSON
- Extrait `data: { photo, url }`

---

## ✅ Checklist de Conformité

### Routes de Profil
- [x] `GET /users/me` - ✅ Conforme
- [x] `PUT /users/me/profile` - ✅ Conforme
- [x] `POST /users/me/photo` - ✅ Conforme (corrigé)
- [x] `GET /users/me/stats` - ✅ Conforme
- [x] `GET /users/:id` - ✅ Conforme
- [x] `GET /users/:id/stats` - ✅ Conforme

### Routes de Recherche
- [x] `GET /users/search` - ✅ Conforme
- [x] `GET /users/autocomplete` - ✅ Conforme

**Conformité: 8/8 endpoints (100%) ✅**

---

## 🎉 Conclusion

**Le service `user_auth_service.dart` est maintenant 100% conforme au controller backend!**

**Corrections appliquées:**
- ✅ Méthode `uploadProfilePhoto()` corrigée
- ✅ Utilise le bon endpoint `/users/me/photo`
- ✅ Format compatible avec Multer/FileInterceptor
- ✅ Workflow optimisé: 1 seul appel API au lieu de 2-3

**Résultat:**
- Tous les endpoints sont parfaitement mappés
- Upload de photo optimisé
- Service prêt pour la production 🚀

---

## 📚 Documentation Complémentaire

Pour comparer avec le service des sociétés, consultez:
- [SOCIETE_MAPPING.md](documentation/SOCIETE_MAPPING.md) - Mapping pour les sociétés
- [GROUPES_MAPPING.md](documentation/GROUPES_MAPPING.md) - Mapping pour les groupes
- [ARCHITECTURE_SERVICES.md](documentation/ARCHITECTURE_SERVICES.md) - Architecture globale
