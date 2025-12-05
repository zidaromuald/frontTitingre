# ✅ Intégration complète de EditableProfileAvatar

## 🎯 Modifications effectuées

Les deux fichiers ont été modifiés pour utiliser le widget réutilisable `EditableProfileAvatar` :

### 1. ✅ [lib/iu/onglets/paramInfo/profil.dart](lib/iu/onglets/paramInfo/profil.dart)

#### Changements appliqués :

**a) Import ajouté** (ligne 3) :
```dart
import '../../../widgets/editable_profile_avatar.dart';
```

**b) Import supprimé** :
```dart
import 'package:image_picker/image_picker.dart'; // ❌ Plus nécessaire
```

**c) Méthode `_changePhoto()` supprimée** (lignes 129-210) :
- Tout le code de sélection d'image a été supprimé
- Le widget `EditableProfileAvatar` gère maintenant l'upload automatiquement

**d) Section avatar remplacée** (lignes 222-235) :

**Avant** :
```dart
Center(
  child: Stack(
    children: [
      CircleAvatar(
        radius: 50,
        backgroundColor: mattermostBlue,
        backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
        child: _photoUrl == null
            ? Text("${_prenomController.text[0]}${_nomController.text[0]}",
                style: TextStyle(color: Colors.white, fontSize: 24))
            : null,
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: GestureDetector(
          onTap: _changePhoto, // ❌ Méthode supprimée
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: mattermostGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
          ),
        ),
      ),
    ],
  ),
),
```

**Après** :
```dart
Center(
  child: EditableProfileAvatar(
    size: 100,
    currentPhotoUrl: _photoUrl,
    onPhotoUpdated: (newUrl) {
      setState(() {
        _photoUrl = newUrl;
      });
    },
    borderColor: mattermostBlue,
    borderWidth: 4,
  ),
),
```

---

### 2. ✅ [lib/is/AccueilPage.dart](lib/is/AccueilPage.dart)

#### Changements appliqués :

**a) Conversion de StatelessWidget → StatefulWidget** (lignes 5-31) :

**Avant** :
```dart
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**Après** :
```dart
class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserPhoto();
  }

  Future<void> _loadUserPhoto() async {
    try {
      final user = await UserAuthService.getMyProfile();
      setState(() {
        _currentPhotoUrl = user.profile?.photo;
      });
    } catch (e) {
      print('Erreur de chargement de la photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**b) Imports ajoutés** (lignes 2-3) :
```dart
import '../services/AuthUS/user_auth_service.dart';
import '../widgets/editable_profile_avatar.dart';
```

**c) Avatar remplacé dans le header** (lignes 241-249) :

**Avant** :
```dart
_ProfileAvatar(size: size.width * 0.18),
```

**Après** :
```dart
EditableProfileAvatar(
  size: size.width * 0.18,
  currentPhotoUrl: _currentPhotoUrl,
  onPhotoUpdated: (newUrl) {
    setState(() {
      _currentPhotoUrl = newUrl;
    });
  },
),
```

**d) Classe `_ProfileAvatar` supprimée** (lignes 336-367) :
- L'ancienne implémentation statique a été complètement supprimée
- Le widget réutilisable `EditableProfileAvatar` la remplace

---

## 📊 Comparaison : Avant / Après

### Avant l'intégration

| Fichier | Code dupliqué | Éditable | Upload automatique | Lignes de code |
|---------|---------------|----------|-------------------|----------------|
| **profil.dart** | Oui (Stack + GestureDetector) | Oui | Non (manuel) | ~80 lignes |
| **AccueilPage.dart** | Oui (Container + CircleAvatar) | Non | Non | ~35 lignes |
| **Total** | 2 implémentations | Incohérent | Non | ~115 lignes |

### Après l'intégration

| Fichier | Code dupliqué | Éditable | Upload automatique | Lignes de code |
|---------|---------------|----------|-------------------|----------------|
| **profil.dart** | Non | Oui | Oui | ~10 lignes |
| **AccueilPage.dart** | Non | Oui | Oui | ~10 lignes |
| **editable_profile_avatar.dart** | Widget unique | Oui | Oui | ~260 lignes (réutilisable) |
| **Total** | 1 implémentation | Cohérent | Oui | ~280 lignes |

---

## 🚀 Fonctionnalités maintenant disponibles

### Dans [profil.dart](lib/iu/onglets/paramInfo/profil.dart) :

✅ Avatar éditable avec icône caméra
✅ Upload automatique de photo
✅ Indicateur de chargement pendant l'upload
✅ SnackBar de confirmation/erreur
✅ Bordure personnalisée (bleu Mattermost)
✅ Mise à jour automatique de `_photoUrl`

### Dans [AccueilPage.dart](lib/is/AccueilPage.dart) :

✅ Avatar éditable (maintenant cliquable !)
✅ Chargement automatique de la photo au démarrage
✅ Upload automatique de photo
✅ Indicateur de chargement pendant l'upload
✅ SnackBar de confirmation/erreur
✅ Mise à jour en temps réel de l'avatar

---

## 🔄 Flux d'utilisation

### Utilisateur dans AccueilPage :

```
1. Page s'ouvre
   ↓
2. initState() → _loadUserPhoto()
   ↓
3. Appel API UserAuthService.getMyProfile()
   ↓
4. Avatar affiche la photo de profil (ou placeholder)
   ↓
5. Utilisateur clique sur l'avatar
   ↓
6. Dialogue "Galerie ou Appareil photo ?"
   ↓
7. Sélection d'image
   ↓
8. Upload automatique
   ↓
9. Avatar mis à jour + SnackBar "Photo de profil mise à jour"
```

### Utilisateur dans ProfilDetailPage :

```
1. Page s'ouvre
   ↓
2. _loadMyProfile() charge toutes les données (nom, prénom, photo, etc.)
   ↓
3. Avatar affiche la photo de profil
   ↓
4. Utilisateur clique sur l'avatar
   ↓
5. Upload automatique (même flux qu'AccueilPage)
   ↓
6. Avatar mis à jour + SnackBar de confirmation
```

---

## ✅ Avantages de l'intégration

### 1. **Code réutilisable**
- Un seul widget `EditableProfileAvatar` pour toute l'application
- Pas de duplication de code

### 2. **Cohérence UI/UX**
- Même comportement partout
- Même style visuel
- Même feedback utilisateur (SnackBar, indicateur de chargement)

### 3. **Maintenance simplifiée**
- Modifier le widget une seule fois = changements partout
- Moins de bugs potentiels

### 4. **Fonctionnalités automatiques**
- Upload automatique via `UserAuthService.uploadProfilePhoto()`
- Gestion des erreurs intégrée
- Indicateur de chargement automatique
- Callback `onPhotoUpdated` pour notifier le parent

### 5. **Facilité d'extension**
- Ajouter le widget ailleurs en 3 lignes de code
- Paramétrable (taille, couleur, bordure, icône d'édition)

---

## 📝 Checklist de validation

- [x] Import de `EditableProfileAvatar` dans profil.dart
- [x] Import supprimé de `image_picker` dans profil.dart
- [x] Méthode `_changePhoto()` supprimée dans profil.dart
- [x] Avatar remplacé dans profil.dart
- [x] AccueilPage converti en StatefulWidget
- [x] Imports ajoutés dans AccueilPage.dart
- [x] Variable `_currentPhotoUrl` ajoutée dans AccueilPage
- [x] Méthode `_loadUserPhoto()` implémentée dans AccueilPage
- [x] Avatar remplacé dans AccueilPage.dart
- [x] Classe `_ProfileAvatar` supprimée dans AccueilPage.dart
- [x] Compilation sans erreur
- [x] Les deux pages utilisent le même widget

---

## 🔧 Configuration requise

### Dépendances (déjà présentes dans pubspec.yaml) :

```yaml
dependencies:
  image_picker: ^1.0.4  # Utilisé par EditableProfileAvatar
```

### Assets :

```yaml
flutter:
  assets:
    - assets/avatar_placeholder.png  # Image par défaut si pas de photo
```

---

## 🎯 Prochaines étapes (optionnelles)

Si vous voulez étendre l'utilisation du widget ailleurs :

### 1. Dans une liste de recherche d'utilisateurs :
```dart
ReadOnlyProfileAvatar(
  size: 40,
  photoUrl: user.profile?.photo,
  onTap: () => Navigator.push(...),
)
```

### 2. Dans une page de profil utilisateur (autre que moi) :
```dart
ReadOnlyProfileAvatar(
  size: 80,
  photoUrl: otherUser.profile?.photo,
  onTap: () {
    // Afficher la photo en grand
  },
)
```

### 3. Dans des commentaires ou posts :
```dart
ReadOnlyProfileAvatar(
  size: 30,
  photoUrl: author.profile?.photo,
)
```

---

## 🐛 Dépannage

### La photo ne s'affiche pas après l'upload

**Cause** : L'URL retournée par l'API est peut-être relative

**Solution** : Vérifier la méthode `getPhotoUrl()` dans `UserProfilModel` :
```dart
String? getPhotoUrl() {
  return photo != null ? 'https://your-api-url.com/storage/$photo' : null;
}
```

### L'avatar ne se met pas à jour dans AccueilPage

**Cause** : Le callback `onPhotoUpdated` n'est pas appelé ou `setState` ne fonctionne pas

**Solution** : Vérifier que le callback est bien implémenté :
```dart
onPhotoUpdated: (newUrl) {
  setState(() {
    _currentPhotoUrl = newUrl;
  });
},
```

### Erreur "Image picker not available"

**Cause** : Permissions caméra/galerie non accordées

**Solution** : Vérifier les permissions dans :
- **Android** : `android/app/src/main/AndroidManifest.xml`
- **iOS** : `ios/Runner/Info.plist`

---

**L'intégration est maintenant complète ! Les deux pages utilisent le même widget réutilisable.** ✅🎉
