# Intégration d'EditableProfileAvatar dans AccueilPage

## 🎯 Objectif

Remplacer l'avatar statique `_ProfileAvatar` par un avatar éditable qui permet de :
1. Afficher la photo de profil de l'utilisateur connecté
2. Permettre de changer la photo en cliquant dessus
3. Upload automatique avec `uploadProfilePhoto()`

---

## 📝 Modifications à apporter

### Étape 1 : Importer le widget

Ajouter en haut du fichier `lib/is/AccueilPage.dart` :

```dart
import 'package:gestauth_clean/widgets/editable_profile_avatar.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
```

---

### Étape 2 : Convertir en StatefulWidget (si nécessaire)

Si `AccueilPage` est actuellement un `StatelessWidget`, le convertir en `StatefulWidget` :

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
      // L'utilisateur n'est peut-être pas connecté
      print('Erreur de chargement de la photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

---

### Étape 3 : Remplacer _ProfileAvatar

Chercher cette ligne dans le fichier (environ ligne 208) :

**Avant** :
```dart
Positioned(
  top: 20,
  left: 16,
  right: 180,
  child: Row(
    children: [
      _ProfileAvatar(size: size.width * 0.18),
      const SizedBox(width: 12),
      // ...
    ],
  ),
),
```

**Après** :
```dart
Positioned(
  top: 20,
  left: 16,
  right: 180,
  child: Row(
    children: [
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
      // ...
    ],
  ),
),
```

---

### Étape 4 : Supprimer l'ancien widget _ProfileAvatar (optionnel)

Si vous n'utilisez plus `_ProfileAvatar` ailleurs, vous pouvez supprimer sa définition :

Chercher et supprimer :
```dart
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.onPrimary.withOpacity(.2), Colors.white24],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: const CircleAvatar(
        backgroundImage: AssetImage('assets/avatar_placeholder.png'),
      ),
    );
  }
}
```

---

## 📋 Code complet de l'exemple

Voici un exemple simplifié de `AccueilPage` avec le nouveau widget :

```dart
import 'package:flutter/material.dart';
import 'package:gestauth_clean/widgets/editable_profile_avatar.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  String? _currentPhotoUrl;
  bool _isLoadingPhoto = true;

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
        _isLoadingPhoto = false;
      });
    } catch (e) {
      setState(() => _isLoadingPhoto = false);
      print('Erreur de chargement de la photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Votre contenu existant (fond, cartes, etc.)
          // ...

          // En-tête avec l'avatar
          Positioned(
            top: 20,
            left: 16,
            right: 180,
            child: Row(
              children: [
                // ✅ Nouvel avatar éditable
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

                // Nom de l'utilisateur, etc.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'John Doe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
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

## 🎯 Résultat attendu

1. **Au chargement de la page** :
   - L'avatar charge la photo depuis `getMyProfile()`
   - Si pas de photo, affiche le placeholder par défaut

2. **Quand l'utilisateur clique sur l'avatar** :
   - Dialogue "Galerie ou Appareil photo ?"
   - Sélection d'image
   - Upload automatique
   - Avatar mis à jour immédiatement
   - SnackBar "Photo de profil mise à jour"

3. **Pendant l'upload** :
   - CircularProgressIndicator affiché sur l'avatar
   - Avatar non cliquable

---

## 🔄 Alternative : Version simplifiée sans chargement initial

Si vous ne voulez pas charger la photo au démarrage (pour gagner en performance) :

```dart
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: 16,
            right: 180,
            child: Row(
              children: [
                // ✅ Avatar éditable sans état
                EditableProfileAvatar(
                  size: size.width * 0.18,
                  // Pas de currentPhotoUrl = charge depuis le cache ou affiche placeholder
                ),
                const SizedBox(width: 12),
                // ...
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

Dans ce cas, l'avatar affichera le placeholder jusqu'à ce que l'utilisateur upload une photo.

---

## ✅ Checklist d'intégration

- [ ] Importer `EditableProfileAvatar` et `UserAuthService`
- [ ] Convertir `AccueilPage` en `StatefulWidget` (si nécessaire)
- [ ] Ajouter la variable `_currentPhotoUrl`
- [ ] Implémenter `_loadUserPhoto()` dans `initState()`
- [ ] Remplacer `_ProfileAvatar` par `EditableProfileAvatar`
- [ ] Ajouter le callback `onPhotoUpdated`
- [ ] Tester l'upload de photo
- [ ] Vérifier que l'avatar s'affiche correctement
- [ ] (Optionnel) Supprimer l'ancien widget `_ProfileAvatar`

---

## 🐛 Dépannage

### La photo ne s'affiche pas

**Cause** : L'URL retournée par l'API est peut-être relative

**Solution** : Vérifier dans `UserProfilModel.getPhotoUrl()` :
```dart
String? getPhotoUrl() {
  return photo != null ? '/storage/$photo' : null;
}
```

Si l'URL est relative, il faut la convertir en URL complète dans le widget.

### L'upload échoue

**Causes possibles** :
1. Token JWT expiré → Reconnecter l'utilisateur
2. Permissions caméra/galerie non accordées
3. Fichier trop volumineux

**Solution** : Vérifier les logs d'erreur dans le SnackBar

---

**Votre AccueilPage est maintenant prête avec un avatar éditable !** 🎉
