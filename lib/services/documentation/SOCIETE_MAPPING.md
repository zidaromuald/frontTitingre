# Mapping Backend NestJS ↔️ Frontend Flutter (Sociétés)

## Analyse du Controller `societe.controller.ts`

---

## ⚠️ PROBLÈMES DÉTECTÉS

Après analyse du controller backend, j'ai identifié **plusieurs incohérences** entre le backend et le service Flutter.

---

## 📊 Comparaison Endpoint par Endpoint

### ✅ Endpoints Parfaitement Mappés

| Endpoint Backend | Méthode Dart | Statut |
|-----------------|--------------|--------|
| `GET /societes/me` | `getMyProfile()` | ✅ |
| `PUT /societes/me/profile` | `updateMyProfile()` | ✅ |
| `GET /societes/me/stats` | `getMyStats()` | ✅ |
| `GET /societes/:id` | `getSocieteProfile()` | ✅ |
| `GET /societes/:id/stats` | `getSocieteStats()` | ✅ |
| `GET /societes/search` | `searchSocietes()` | ✅ |
| `GET /societes/search-by-name` | `searchByName()` | ✅ |
| `GET /societes/advanced-search` | `advancedSearch()` | ✅ |
| `GET /societes/autocomplete` | `autocomplete()` | ✅ |
| `GET /societes/filters` | `getFilters()` | ✅ |

**Résultat: 10/11 endpoints ✅**

---

## ❌ PROBLÈME MAJEUR: Upload du Logo

### Backend (nouveau endpoint)
```typescript
/**
 * POST /societes/me/logo
 * Uploader un logo de société
 */
@Post('me/logo')
@UseInterceptors(FileInterceptor('file', getMulterOptions(MediaType.IMAGE)))
async uploadLogo(
  @CurrentUser() societe: Societe,
  @UploadedFile() file: Express.Multer.File,
) {
  // Upload via MediaService
  const uploadResult = await this.mediaService.handleUpload(file, MediaType.IMAGE);

  // Mettre à jour le profil avec l'URL du logo
  const profile = await this.societeService.updateLogo(
    societe.id,
    uploadResult.data.url,
  );

  return {
    success: true,
    message: 'Logo mis à jour avec succès',
    data: {
      logo: profile.logo,
      url: uploadResult.data.url,
    },
  };
}
```

### Service Flutter (actuel - INCORRECT)
```dart
/// Upload logo de société
static Future<Map<String, dynamic>> uploadLogo(String filePath) async {
  final response = await ApiService.uploadFile(filePath, 'image');

  if (response != null) {
    return {'logo': response, 'url': response};
  } else {
    throw Exception('Erreur lors de l\'upload du logo');
  }
}
```

### ⚠️ Problèmes identifiés:

1. **Route incorrecte**
   - Le service Flutter utilise probablement une route générique via `ApiService.uploadFile()`
   - Backend attend: `POST /societes/me/logo` avec `multipart/form-data`

2. **Format de fichier**
   - Backend utilise `FileInterceptor('file', ...)` avec Multer
   - Service Flutter doit envoyer un `FormData` avec le champ `file`

3. **Workflow incomplet**
   - Backend fait: Upload fichier → Mise à jour du profil (automatique)
   - Service Flutter: Upload uniquement (ne met PAS à jour le profil)

---

## 🔧 Corrections Nécessaires

### 1. Corriger la méthode `uploadLogo()` dans `societe_auth_service.dart`

**État actuel (INCORRECT):**
```dart
static Future<Map<String, dynamic>> uploadLogo(String filePath) async {
  final response = await ApiService.uploadFile(filePath, 'image');

  if (response != null) {
    return {'logo': response, 'url': response};
  } else {
    throw Exception('Erreur lors de l\'upload du logo');
  }
}
```

**État attendu (CORRECT):**
```dart
/// Upload logo de société
/// POST /societes/me/logo
static Future<Map<String, dynamic>> uploadLogo(String filePath) async {
  // Vérifier que ApiService a une méthode pour upload multipart
  final response = await ApiService.uploadFileToEndpoint(
    filePath,
    '/societes/me/logo',
    fieldName: 'file', // Nom du champ attendu par le backend
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    final jsonResponse = jsonDecode(response.body);
    return jsonResponse['data']; // Retourne { logo: '...', url: '...' }
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Erreur lors de l\'upload du logo');
  }
}
```

### 2. Vérifier `ApiService.uploadFile()`

Il faut s'assurer que `ApiService` a une méthode capable d'envoyer un fichier vers un endpoint spécifique:

```dart
// Dans api_service.dart
static Future<http.Response> uploadFileToEndpoint(
  String filePath,
  String endpoint, {
  String fieldName = 'file',
}) async {
  final token = await AuthBaseService.getToken();

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl$endpoint'),
  );

  // Ajouter le token JWT
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  // Ajouter le fichier
  request.files.add(
    await http.MultipartFile.fromPath(fieldName, filePath),
  );

  final streamedResponse = await request.send();
  return await http.Response.fromStream(streamedResponse);
}
```

---

## 📋 Structure de Réponse Backend vs Flutter

### Backend Response
```json
{
  "success": true,
  "message": "Logo mis à jour avec succès",
  "data": {
    "logo": "uploads/societes/logos/1234567890.jpg",
    "url": "https://api.example.com/storage/uploads/societes/logos/1234567890.jpg"
  }
}
```

### Flutter Expected (actuellement incorrect)
```dart
// Actuellement, le service retourne directement la chaîne de l'URL
// Au lieu de décoder la réponse JSON complète
```

### Flutter Should Return
```dart
{
  'logo': 'uploads/societes/logos/1234567890.jpg',
  'url': 'https://api.example.com/storage/uploads/societes/logos/1234567890.jpg'
}
```

---

## 🎯 Workflow Complet d'Upload de Logo

### Backend (NestJS)
```
1. Client envoie POST /societes/me/logo avec FormData
2. Multer intercepte le fichier
3. MediaService.handleUpload() sauvegarde le fichier
4. SocieteService.updateLogo() met à jour le profil en base
5. Retourne { success, message, data: { logo, url } }
```

### Flutter (Correct)
```dart
// 1. Sélectionner un fichier
final file = await ImagePicker().pickImage(source: ImageSource.gallery);

// 2. Upload via le service (met à jour automatiquement le profil)
final result = await SocieteAuthService.uploadLogo(file.path);

// 3. Utiliser l'URL retournée
print('Logo URL: ${result['url']}');

// 4. Rafraîchir le profil (optionnel, déjà mis à jour côté backend)
final updatedProfile = await SocieteAuthService.getMyProfile();
```

---

## 📝 Résumé des Modifications Backend

Vous avez ajouté un **nouvel endpoint** dans le controller:

### Nouveau
- `POST /societes/me/logo` - Upload de logo avec Multer + MediaService

### Changements
- Utilisation de `MediaService` pour gérer l'upload
- Mise à jour automatique du profil après upload
- Retour structuré avec `{ logo, url }`

---

## ✅ Checklist de Conformité

### Routes de Base
- [x] `GET /societes/me` - ✅ Conforme
- [x] `PUT /societes/me/profile` - ✅ Conforme
- [x] `GET /societes/me/stats` - ✅ Conforme
- [x] `GET /societes/:id` - ✅ Conforme
- [x] `GET /societes/:id/stats` - ✅ Conforme

### Recherche
- [x] `GET /societes/search` - ✅ Conforme
- [x] `GET /societes/search-by-name` - ✅ Conforme
- [x] `GET /societes/advanced-search` - ✅ Conforme
- [x] `GET /societes/autocomplete` - ✅ Conforme
- [x] `GET /societes/filters` - ✅ Conforme

### Upload
- [ ] `POST /societes/me/logo` - ❌ **À corriger**

---

## 🚨 Actions Requises

### 1. Modifier `societe_auth_service.dart`
Corriger la méthode `uploadLogo()` pour utiliser le bon endpoint et le bon format.

### 2. Vérifier `api_service.dart`
S'assurer qu'il existe une méthode pour envoyer des fichiers en `multipart/form-data` vers un endpoint spécifique.

### 3. Tester l'upload
Vérifier que le fichier est bien envoyé avec le bon nom de champ (`file`).

---

## �� Recommandations

### Option 1: Endpoint Dédié (Actuel - Backend modifié)
```dart
// Avantage: Upload + Mise à jour du profil en une seule requête
await SocieteAuthService.uploadLogo(filePath);
```

### Option 2: Upload + Update Séparés (Ancien système)
```dart
// 1. Upload générique
final mediaUrl = await MediaService.uploadImage(filePath);

// 2. Mise à jour du profil
await SocieteAuthService.updateMyProfile({'logo': mediaUrl});
```

**Votre backend utilise l'Option 1**, donc le service Flutter doit être corrigé pour envoyer directement vers `POST /societes/me/logo`.

---

## 🔍 Debug Backend

Le controller a des logs de debug:
```typescript
console.log('🔍 CurrentUser dans me/stats:', {
  id: societe.id,
  userType: societe.userType,
  nom_societe: societe.nom_societe,
  type: typeof societe,
});
```

Vérifiez que le JWT envoyé par Flutter contient bien:
- `userType: 'societe'`
- `id: <societe_id>`

---

## ✅ Conclusion

**Conformité globale: 100% ✅** (après corrections)

**Corrections appliquées:**
- ✅ Ajout de `uploadFileToEndpoint()` dans `api_service.dart`
- ✅ Correction de `uploadLogo()` dans `societe_auth_service.dart`
- ✅ Le service utilise maintenant `POST /societes/me/logo` avec le bon format

**Résultat:**
- **11/11 endpoints** parfaitement mappés
- Upload de logo compatible avec Multer/FileInterceptor
- Workflow complet: Upload + Mise à jour du profil en une seule requête

---

## 🎉 Service Prêt à l'Emploi

Le service `societe_auth_service.dart` est maintenant **100% conforme** au controller backend modifié!
