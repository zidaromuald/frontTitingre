# 🏢 EditableSocieteAvatar - Widget de logo éditable pour sociétés

## 📖 Description

Widget réutilisable pour afficher et modifier le logo d'une société. Spécifiquement conçu pour les sociétés, il utilise `SocieteAuthService.uploadLogo()` au lieu de `UserAuthService.uploadProfilePhoto()`.

## ✨ Fonctionnalités

- ✅ Affichage du logo de la société
- ✅ Icône business par défaut si pas de logo
- ✅ Clic pour changer le logo (galerie ou appareil photo)
- ✅ Upload automatique avec `SocieteAuthService.uploadLogo()`
- ✅ Indicateur de chargement pendant l'upload
- ✅ Messages de succès/erreur
- ✅ Icône de caméra pour indiquer l'édition
- ✅ Bordure personnalisable
- ✅ Callback pour notifier le parent

## 🔧 Utilisation

### Import

```dart
import '../../../widgets/editable_societe_avatar.dart';
```

### Exemple basique

```dart
EditableSocieteAvatar(
  size: 100,
  currentLogoUrl: _logoUrl,
  onLogoUpdated: (newUrl) {
    setState(() {
      _logoUrl = newUrl;
    });
  },
)
```

### Exemple avec personnalisation

```dart
EditableSocieteAvatar(
  size: 120,
  currentLogoUrl: societe.profile?.logo,
  onLogoUpdated: (newUrl) {
    setState(() {
      _logoUrl = newUrl;
    });
  },
  borderColor: Color(0xff5ac18e),
  borderWidth: 4,
  showEditIcon: true,
)
```

## 📝 Paramètres

| Paramètre | Type | Requis | Description |
|-----------|------|--------|-------------|
| `size` | `double` | ✅ | Taille de l'avatar (largeur et hauteur) |
| `currentLogoUrl` | `String?` | ❌ | URL actuelle du logo |
| `onLogoUpdated` | `Function(String)?` | ❌ | Callback appelé après upload réussi |
| `showEditIcon` | `bool` | ❌ | Afficher l'icône de caméra (défaut: `true`) |
| `borderColor` | `Color?` | ❌ | Couleur de la bordure |
| `borderWidth` | `double` | ❌ | Largeur de la bordure (défaut: `3`) |

## 🎯 Différence avec EditableProfileAvatar

| Aspect | EditableProfileAvatar | EditableSocieteAvatar |
|--------|----------------------|----------------------|
| **Usage** | Pour les **users** | Pour les **sociétés** |
| **Service** | `UserAuthService.uploadProfilePhoto()` | `SocieteAuthService.uploadLogo()` |
| **Paramètre URL** | `currentPhotoUrl` | `currentLogoUrl` |
| **Callback** | `onPhotoUpdated` | `onLogoUpdated` |
| **Icône par défaut** | Initiales (nom+prénom) | Icône `Icons.business` |
| **Champ dans réponse** | `response['photo']` | `response['logo']` |

## 💡 Exemples d'utilisation

### 1. Dans la page de profil société (éditable)

**Fichier:** `lib/is/onglets/paramInfo/profil.dart`

```dart
class _ProfilDetailPageState extends State<ProfilDetailPage> {
  String? _logoUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Logo éditable
          Center(
            child: EditableSocieteAvatar(
              size: 100,
              currentLogoUrl: _logoUrl,
              onLogoUpdated: (newUrl) {
                setState(() {
                  _logoUrl = newUrl;
                });
              },
              borderColor: Color(0xff5ac18e),
              borderWidth: 4,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 2. Dans une page d'accueil société

```dart
class AccueilSocietePage extends StatefulWidget {
  @override
  State<AccueilSocietePage> createState() => _AccueilSocietePageState();
}

class _AccueilSocietePageState extends State<AccueilSocietePage> {
  String? _currentLogoUrl;

  @override
  void initState() {
    super.initState();
    _loadSocieteLogo();
  }

  Future<void> _loadSocieteLogo() async {
    try {
      final societe = await SocieteAuthService.getMyProfile();
      setState(() {
        _currentLogoUrl = societe.profile?.logo;
      });
    } catch (e) {
      print('Erreur de chargement du logo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            EditableSocieteAvatar(
              size: 40,
              currentLogoUrl: _currentLogoUrl,
              onLogoUpdated: (newUrl) {
                setState(() {
                  _currentLogoUrl = newUrl;
                });
              },
              showEditIcon: true,
            ),
            SizedBox(width: 12),
            Text('Ma Société'),
          ],
        ),
      ),
    );
  }
}
```

## 🔄 Flux d'upload du logo

```
Utilisateur clique sur l'avatar
    ↓
Dialogue: Choisir Galerie ou Appareil photo
    ↓
Sélection de l'image avec ImagePicker
    ↓
setState(() => _isUploading = true)
    ↓
Appel à SocieteAuthService.uploadLogo(imagePath)
    ↓
API: POST /societes/me/logo (multipart/form-data)
    ↓
Réponse: { logo: "path/to/logo.png", url: "..." }
    ↓
Mise à jour de _logoUrl avec response['logo']
    ↓
Appel du callback onLogoUpdated(newUrl) si fourni
    ↓
setState(() => _isUploading = false)
    ↓
Affichage du nouveau logo + SnackBar de succès
```

## ⚠️ Gestion des erreurs

Le widget gère automatiquement les erreurs :

```dart
try {
  final response = await SocieteAuthService.uploadLogo(image.path);
  // Mise à jour réussie
} catch (e) {
  // Affichage automatique d'un SnackBar d'erreur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur lors de l\'upload: ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## 🎨 Personnalisation de l'apparence

### Logo avec bordure verte

```dart
EditableSocieteAvatar(
  size: 100,
  currentLogoUrl: _logoUrl,
  onLogoUpdated: (newUrl) => setState(() => _logoUrl = newUrl),
  borderColor: Color(0xff5ac18e), // Vert
  borderWidth: 4,
)
```

### Logo sans icône d'édition

```dart
EditableSocieteAvatar(
  size: 80,
  currentLogoUrl: _logoUrl,
  onLogoUpdated: (newUrl) => setState(() => _logoUrl = newUrl),
  showEditIcon: false, // Masquer l'icône caméra
)
```

### Petit logo pour header

```dart
EditableSocieteAvatar(
  size: 40,
  currentLogoUrl: _logoUrl,
  onLogoUpdated: (newUrl) => setState(() => _logoUrl = newUrl),
  borderWidth: 2,
)
```

## 🔗 Widgets associés

- **ReadOnlyProfileAvatar** - Pour afficher le logo d'une société en lecture seule (profil public)
- **EditableProfileAvatar** - Équivalent pour les users
- **EditableSocieteAvatar** - Pour les sociétés (ce widget)

## 📂 Emplacement

```
lib/
└── widgets/
    ├── editable_profile_avatar.dart      # Pour les users
    └── editable_societe_avatar.dart      # ✅ Pour les sociétés
```

## ✅ Résumé

Ce widget est la version **société** du `EditableProfileAvatar`. Il permet aux sociétés de modifier leur logo de la même manière que les users peuvent modifier leur photo de profil, mais en utilisant le service approprié (`SocieteAuthService`).

**Utilisez ce widget dans :**
- ✅ Page de profil société éditable (`is/onglets/paramInfo/profil.dart`)
- ✅ Header/AppBar d'une page société
- ✅ Toute page où une société peut modifier son logo
