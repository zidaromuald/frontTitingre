# Page Mon Profil - Fonctionnement

## 📋 Résumé

Cette page permet à l'utilisateur connecté de :
1. **Consulter** son profil personnel
2. **Modifier** ses informations (bio, expérience, formation, compétences)
3. **Changer** sa photo de profil

---

## 🔄 Flux de fonctionnement

### 1. Chargement initial (`initState()`)

```
initState()
  ↓
_loadMyProfile()
  ↓
UserAuthService.getMyProfile() → Appel API GET /users/me
  ↓
Remplir les TextEditingController avec les données récupérées
  ↓
Affichage de la page
```

**Endpoint utilisé** : `UserAuthService.getMyProfile()`
- **Route API** : `GET /users/me`
- **Retourne** : `UserModel` avec toutes les informations de l'utilisateur connecté

---

### 2. Sauvegarde des modifications (Clic sur l'icône Save)

```
Clic sur icône Save (en haut à droite)
  ↓
_saveProfile()
  ↓
Préparer les données modifiées (bio, expérience, formation, compétences)
  ↓
UserAuthService.updateMyProfile(updates) → Appel API PUT /users/me/profile
  ↓
Affichage SnackBar "Profil sauvegardé avec succès"
```

**Endpoint utilisé** : `UserAuthService.updateMyProfile(updates)`
- **Route API** : `PUT /users/me/profile`
- **Données envoyées** :
  ```json
  {
    "bio": "Ma biographie...",
    "experience_pro": "Mon expérience...",
    "formation": "Ma formation...",
    "competences": ["Flutter", "Dart", "Firebase"]
  }
  ```
- **Retourne** : `UserProfilModel` mis à jour

---

### 3. Changement de photo (Clic sur l'icône caméra)

```
Clic sur icône caméra (en bas à droite de la photo)
  ↓
_changePhoto()
  ↓
Afficher dialogue : Galerie ou Appareil photo ?
  ↓
ImagePicker.pickImage(source: ImageSource.gallery/camera)
  ↓
Afficher indicateur de chargement
  ↓
UserAuthService.uploadProfilePhoto(filePath) → Appel API POST /users/me/photo
  ↓
Mettre à jour _photoUrl avec l'URL retournée
  ↓
Affichage SnackBar "Photo de profil mise à jour"
```

**Endpoint utilisé** : `UserAuthService.uploadProfilePhoto(filePath)`
- **Route API** : `POST /users/me/photo`
- **Type** : Multipart form-data
- **Champ** : `file`
- **Retourne** :
  ```json
  {
    "photo_profil": "https://...",
    "url": "https://..."
  }
  ```

---

## 📊 Structure de la page

### Sections affichées

1. **Photo de profil** (modifiable)
   - CircleAvatar avec la photo actuelle
   - Bouton caméra pour changer la photo

2. **Informations en lecture seule** (non modifiables)
   - Nom
   - Prénom
   - Email
   - Numéro de téléphone
   - Icône cadenas pour indiquer qu'elles ne sont pas modifiables

3. **Informations modifiables**
   - Bio (3 lignes)
   - Expérience professionnelle (2 lignes)
   - Formation (2 lignes)

4. **Compétences**
   - Liste de chips (étiquettes)
   - Bouton "Ajouter une compétence"
   - Possibilité de retirer une compétence (croix sur chaque chip)

---

## 🎨 Logique de l'interface

### Champs en lecture seule vs modifiables

**Pourquoi cette séparation ?**

Les champs **nom, prénom, email, téléphone** sont gérés directement dans le `UserModel` et ne peuvent pas être modifiés via l'endpoint `/users/me/profile`. Ils sont donc affichés en **lecture seule** avec une icône cadenas.

Les champs **bio, expérience, formation, compétences** font partie du `UserProfilModel` et peuvent être modifiés via l'endpoint `/users/me/profile`.

### Widget `_buildReadOnlyCard()`

```dart
_buildReadOnlyCard("Nom", _nomController.text)
```

Affiche un champ avec :
- Un label en gris
- La valeur actuelle
- Une icône cadenas à droite

### Widget `_buildTextField()`

```dart
_buildTextField("Bio", _bioController, maxLines: 3)
```

Affiche un champ de texte modifiable avec :
- Un label
- Un fond blanc
- Une bordure bleue au focus

---

## 🔄 Gestion de l'état

### Variables d'état

| Variable | Type | Rôle |
|----------|------|------|
| `_isLoading` | `bool` | Indique si les données sont en cours de chargement |
| `_isSaving` | `bool` | Indique si la sauvegarde est en cours |
| `_photoUrl` | `String?` | URL de la photo de profil |
| `_userProfile` | `Map?` | Données brutes du profil |
| `_competences` | `List<String>` | Liste des compétences |

### Indicateurs visuels

1. **Chargement initial** : `CircularProgressIndicator` au centre
2. **Sauvegarde en cours** : `CircularProgressIndicator` dans le bouton Save
3. **Upload photo** : Dialogue modal avec `CircularProgressIndicator`

---

## ⚙️ Fonctionnalités additionnelles

### 1. Pull-to-refresh

```dart
RefreshIndicator(
  onRefresh: _loadMyProfile,
  child: SingleChildScrollView(...)
)
```

Permet de tirer vers le bas pour recharger les données.

### 2. Gestion des erreurs

Toutes les opérations sont dans des blocs `try-catch` :
- Affichage d'un `SnackBar` rouge en cas d'erreur
- Restauration de l'état précédent

### 3. Compétences dynamiques

- **Ajouter** : Dialogue avec un TextField
- **Retirer** : Clic sur la croix du Chip
- **Sauvegarde** : Incluses dans `_saveProfile()`

---

## 🎯 Exemple d'utilisation complète

### Scénario : Modifier mon profil

1. **Ouverture de la page**
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(builder: (_) => ProfilDetailPage()),
   );
   ```

2. **La page charge automatiquement les données**
   - Appel `getMyProfile()`
   - Affichage des informations

3. **L'utilisateur modifie sa bio**
   - Tape dans le champ "Bio"
   - Le `_bioController` est mis à jour

4. **L'utilisateur ajoute une compétence**
   - Clic sur "Ajouter une compétence"
   - Dialogue s'ouvre
   - Tape "Flutter"
   - Clic "Ajouter"
   - "Flutter" s'ajoute à la liste

5. **L'utilisateur change sa photo**
   - Clic sur l'icône caméra
   - Sélectionne "Galerie"
   - Choisit une photo
   - Upload automatique
   - Photo mise à jour immédiatement

6. **L'utilisateur sauvegarde**
   - Clic sur l'icône Save (en haut à droite)
   - Appel `updateMyProfile()`
   - SnackBar "Profil sauvegardé avec succès"

---

## ✅ Validation de ton raisonnement

**Ta logique est 100% correcte !**

| Ce que tu as dit | Implémentation |
|------------------|----------------|
| "Lier avec `getMyProfile()` pour accéder à son compte" | ✅ Fait dans `_loadMyProfile()` |
| "Icône en haut à droite pour modifier" | ✅ Bouton Save dans AppBar actions |
| "Utiliser `updateMyProfile()` pour modifier" | ✅ Fait dans `_saveProfile()` |
| "Utiliser `uploadProfilePhoto()` pour changer la photo" | ✅ Fait dans `_changePhoto()` |
| "Accéder à la galerie" | ✅ `ImagePicker` avec choix Galerie/Caméra |

---

## 📱 Intégration dans l'application

Pour naviguer vers cette page depuis un menu ou un onglet :

```dart
// Depuis un drawer, bottom navigation, ou autre
ListTile(
  leading: Icon(Icons.person),
  title: Text('Mon Profil'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilDetailPage(),
      ),
    );
  },
)
```

---

## 🚀 Prochaines améliorations possibles

1. **Validation des champs** : Vérifier que la bio ne dépasse pas X caractères
2. **Compression d'images** : Réduire la taille avant upload
3. **Cache local** : Sauvegarder les données en local avec `shared_preferences`
4. **Modification du nom/prénom** : Ajouter un endpoint dédié si besoin

---

**Ton raisonnement est parfait ! La page est maintenant fonctionnelle et connectée aux bons endpoints.** 🎉
