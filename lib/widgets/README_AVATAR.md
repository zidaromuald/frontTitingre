# Widget EditableProfileAvatar - Guide d'utilisation

## 📋 Description

Deux widgets d'avatar de profil réutilisables :

1. **`EditableProfileAvatar`** - Avatar éditable (pour MON profil)
   - Permet de cliquer pour changer la photo
   - Upload automatique avec `uploadProfilePhoto()`
   - Affiche un indicateur de chargement pendant l'upload

2. **`ReadOnlyProfileAvatar`** - Avatar en lecture seule (pour les AUTRES utilisateurs)
   - Affiche uniquement la photo
   - Pas d'édition possible
   - Optionnel : `onTap` pour naviguer vers le profil

---

## 🎯 Cas d'usage 1 : AccueilPage (Mon avatar éditable)

### Utilisation dans AccueilPage

**Fichier** : `lib/is/AccueilPage.dart`

**Avant** :
```dart
_ProfileAvatar(size: size.width * 0.18),
```

**Après** :
```dart
import 'package:gestauth_clean/widgets/editable_profile_avatar.dart';

// Dans le build
EditableProfileAvatar(
  size: size.width * 0.18,
  currentPhotoUrl: currentUser?.profile?.photo, // URL actuelle
  onPhotoUpdated: (newUrl) {
    // Optionnel : mettre à jour l'état
    setState(() {
      // Rafraîchir l'affichage si nécessaire
    });
  },
  showEditIcon: true, // Afficher l'icône caméra
)
```

---

## 🎯 Cas d'usage 2 : Page de profil (ProfilDetailPage)

**Fichier** : `lib/iu/onglets/paramInfo/profil.dart`

**Remplacer l'avatar actuel par** :
```dart
import 'package:gestauth_clean/widgets/editable_profile_avatar.dart';

// Dans le build
EditableProfileAvatar(
  size: 100,
  currentPhotoUrl: _photoUrl,
  onPhotoUpdated: (newUrl) {
    setState(() {
      _photoUrl = newUrl;
    });
  },
  borderColor: mattermostBlue,
  borderWidth: 4,
)
```

---

## 🎯 Cas d'usage 3 : Voir le profil d'un AUTRE utilisateur

**Exemple** : Page de profil utilisateur

```dart
import 'package:gestauth_clean/widgets/editable_profile_avatar.dart';

// Dans le build
ReadOnlyProfileAvatar(
  size: 80,
  photoUrl: otherUser.profile?.photo,
  onTap: () {
    // Optionnel : afficher la photo en grand
    showDialog(
      context: context,
      builder: (_) => PhotoViewDialog(photoUrl: otherUser.profile?.photo),
    );
  },
)
```

---

## 🎯 Cas d'usage 4 : Liste d'utilisateurs (petits avatars)

**Exemple** : Liste de résultats de recherche

```dart
ReadOnlyProfileAvatar(
  size: 40,
  photoUrl: user.profile?.photo,
  borderWidth: 2,
  onTap: () {
    // Naviguer vers le profil de l'utilisateur
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(userId: user.id),
      ),
    );
  },
)
```

---

## 📊 Paramètres disponibles

### EditableProfileAvatar (éditable)

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `size` | `double` | Taille de l'avatar (obligatoire) | - |
| `currentPhotoUrl` | `String?` | URL de la photo actuelle | `null` |
| `onPhotoUpdated` | `Function(String)?` | Callback quand la photo change | `null` |
| `showEditIcon` | `bool` | Afficher l'icône caméra | `true` |
| `borderColor` | `Color?` | Couleur de la bordure | Dégradé par défaut |
| `borderWidth` | `double` | Largeur de la bordure | `3` |

### ReadOnlyProfileAvatar (lecture seule)

| Paramètre | Type | Description | Défaut |
|-----------|------|-------------|--------|
| `size` | `double` | Taille de l'avatar (obligatoire) | - |
| `photoUrl` | `String?` | URL de la photo | `null` |
| `borderColor` | `Color?` | Couleur de la bordure | Dégradé par défaut |
| `borderWidth` | `double` | Largeur de la bordure | `3` |
| `onTap` | `VoidCallback?` | Action au clic | `null` |

---

## 🔄 Flux d'upload (EditableProfileAvatar)

```
Clic sur l'avatar
    ↓
Dialogue : Galerie ou Appareil photo ?
    ↓
ImagePicker.pickImage()
    ↓
Afficher CircularProgressIndicator
    ↓
UserAuthService.uploadProfilePhoto(path)
    ↓
API POST /users/me/photo
    ↓
Réponse { photo: '...', url: '...' }
    ↓
setState(() => _photoUrl = newUrl)
    ↓
onPhotoUpdated?.call(newUrl) → Notifier le parent
    ↓
SnackBar "Photo de profil mise à jour"
```

---

## 📝 Exemple complet : Intégration dans AccueilPage

### Étape 1 : Importer le widget

```dart
import 'package:gestauth_clean/widgets/editable_profile_avatar.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
```

### Étape 2 : Ajouter un état pour l'URL de la photo

Si AccueilPage est un `StatelessWidget`, il faut le convertir en `StatefulWidget` :

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
      // Gérer l'erreur
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ... Votre contenu existant

          Positioned(
            top: 20,
            left: 16,
            right: 180,
            child: Row(
              children: [
                // ✅ Remplacer _ProfileAvatar par EditableProfileAvatar
                EditableProfileAvatar(
                  size: size.width * 0.18,
                  currentPhotoUrl: _currentPhotoUrl,
                  onPhotoUpdated: (newUrl) {
                    setState(() {
                      _currentPhotoUrl = newUrl;
                    });
                  },
                ),
                const SizedBox(width: 12),
                // ... Le reste de votre Row
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

## 🎨 Personnalisation

### Avatar avec bordure colorée

```dart
EditableProfileAvatar(
  size: 100,
  currentPhotoUrl: _photoUrl,
  borderColor: Colors.blue,
  borderWidth: 5,
)
```

### Avatar sans icône d'édition (mode aperçu)

```dart
EditableProfileAvatar(
  size: 100,
  currentPhotoUrl: _photoUrl,
  showEditIcon: false,
)
```

### Avatar lecture seule avec action personnalisée

```dart
ReadOnlyProfileAvatar(
  size: 60,
  photoUrl: user.profile?.photo,
  onTap: () {
    print('Clic sur l\'avatar de ${user.nom}');
  },
)
```

---

## ⚠️ Notes importantes

1. **Image placeholder** : Le widget utilise `assets/avatar_placeholder.png` par défaut
   - Assurez-vous que cette image existe dans votre dossier `assets/`
   - Ou modifiez le chemin dans le widget

2. **Permission** : L'upload nécessite les permissions caméra/galerie
   - Déjà configuré avec `image_picker` dans `pubspec.yaml`

3. **Authentification** : `uploadProfilePhoto()` nécessite un token JWT valide
   - L'utilisateur doit être connecté

4. **Callback `onPhotoUpdated`** : Optionnel mais recommandé
   - Permet de mettre à jour l'état du parent
   - Utile si l'avatar est affiché à plusieurs endroits

---

## 🚀 Migration rapide

### Remplacer tous les anciens avatars

**Rechercher dans votre projet** :
```dart
_ProfileAvatar(size: ...)
```

**Remplacer par** :
```dart
EditableProfileAvatar(
  size: ...,
  currentPhotoUrl: _photoUrl,
)
```

Ou pour les avatars non éditables :
```dart
ReadOnlyProfileAvatar(
  size: ...,
  photoUrl: user.profile?.photo,
)
```

---

## ✅ Avantages

- ✅ **Réutilisable** : Un seul widget pour toute l'app
- ✅ **Upload automatique** : Pas besoin de gérer l'upload manuellement
- ✅ **UX optimale** : Indicateur de chargement, messages d'erreur
- ✅ **Flexible** : Personnalisable (taille, couleur, bordure)
- ✅ **Sécurisé** : Utilise l'API authentifiée

---

**Le widget est prêt à l'emploi ! Il suffit de l'importer et de l'utiliser.** 🎉
