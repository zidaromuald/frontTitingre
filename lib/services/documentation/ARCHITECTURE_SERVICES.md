# 🏗️ Architecture des Services - Titingre

## 📁 Structure Créée

```
lib/services/
├── api_service.dart                    # Service HTTP de base
├── auth_base_service.dart              # Logique commune User/Societe
├── user_auth_service.dart              # Auth User + UserModel
├── societe_auth_service.dart           # Auth Societe + SocieteModel
├── unified_auth_service.dart           # Service unifié (détection auto)
├── post_service.dart                   # Gestion des posts
├── media_service.dart                  # ✨ Upload médias (séparé)
├── exemple_utilisation.dart            # Exemples posts
├── EXEMPLES_AUTHENTIFICATION.dart      # Exemples auth
├── MEDIA_USAGE_EXAMPLE.md              # ✨ Exemples média
├── README.md                           # Documentation
└── ARCHITECTURE_SERVICES.md            # Ce fichier
```

---

## 🎯 Réponse à Votre Question

### **Question : Service Général ou Service par Type ?**

**Réponse : HYBRIDE (le meilleur des deux mondes) ✅**

### Pourquoi cette approche ?

#### ✅ Avantages de l'Architecture Hybride

1. **`auth_base_service.dart`** - Logique commune
   - Sauvegarde du token JWT
   - Gestion du cache local
   - Détection du type d'utilisateur
   - Déconnexion

2. **`user_auth_service.dart`** - Spécifique User
   - Routes : `/auth/register`, `/auth/login`, `/auth/me`
   - Modèle `UserModel` avec `nom`, `prenom`, `email`
   - Recherche d'utilisateurs

3. **`societe_auth_service.dart`** - Spécifique Societe
   - Routes : `/auth/societe/register`, `/auth/societe/login`
   - Modèle `SocieteModel` avec `nom`, `secteurActivite`
   - Recherche de sociétés

4. **`unified_auth_service.dart`** - Service unifié
   - Détecte automatiquement User ou Societe
   - Interface simple pour widgets génériques
   - Évite la duplication de code

---

## 🔄 Comparaison des Approches

### ❌ Option 1 : Un Seul Service Général (PAS OPTIMAL)

```dart
// ❌ PROBLÈME : Trop de conditions
class AuthService {
  static Future<dynamic> login(String type, String email, String password) async {
    if (type == 'user') {
      // Code User
    } else if (type == 'societe') {
      // Code Societe
    }
  }
}
```

**Inconvénients :**
- Code illisible avec trop de `if/else`
- Modèles différents difficiles à gérer
- Maintenance complexe

### ❌ Option 2 : Services Complètement Séparés (DUPLICATION)

```dart
// ❌ PROBLÈME : Code dupliqué
class UserAuthService {
  static Future<void> saveToken(String token) { /* ... */ }
  static Future<void> logout() { /* ... */ }
}

class SocieteAuthService {
  static Future<void> saveToken(String token) { /* ... */ } // DUPLIQUÉ !
  static Future<void> logout() { /* ... */ }                  // DUPLIQUÉ !
}
```

**Inconvénients :**
- Duplication de code
- Bugs difficiles à corriger (2 endroits)

### ✅ Option 3 : HYBRIDE (NOTRE CHOIX)

```dart
// ✅ OPTIMAL : Base commune + Spécialisations
auth_base_service.dart      → Logique commune
user_auth_service.dart      → Spécifique User
societe_auth_service.dart   → Spécifique Societe
unified_auth_service.dart   → Interface unifiée
```

**Avantages :**
- ✅ Pas de duplication (code commun dans `auth_base_service`)
- ✅ Clarté (chaque service a son rôle)
- ✅ Maintenabilité (modification facile)
- ✅ Flexibilité (facile d'ajouter un 3ème type)

---

## 🎨 Utilisation Selon le Contexte

### 📱 Page de Connexion SPÉCIFIQUE (User ou Societe)

Utilisez le service spécifique :

```dart
// Page LoginUser.dart
import 'services/user_auth_service.dart';

final user = await UserAuthService.login(
  identifiant: email,
  password: password,
);
```

```dart
// Page LoginSociete.dart
import 'services/societe_auth_service.dart';

final societe = await SocieteAuthService.login(
  identifiant: email,
  password: password,
);
```

### 📱 Page GÉNÉRIQUE (HomePage, Settings, etc.)

Utilisez le service unifié :

```dart
// HomePage.dart - Affiche User OU Societe
import 'services/unified_auth_service.dart';

final currentUser = await UnifiedAuthService.getCurrentEntity();

if (currentUser is UserModel) {
  // Afficher interface User
  print('Bienvenue ${currentUser.fullName}');
} else if (currentUser is SocieteModel) {
  // Afficher interface Societe
  print('Bienvenue ${currentUser.nom}');
}
```

### 📱 Widget de Déconnexion

```dart
// Bouton déconnexion universel
import 'services/unified_auth_service.dart';

ElevatedButton(
  onPressed: () async {
    await UnifiedAuthService.logout(); // Marche pour User ET Societe
    Navigator.pushReplacementNamed(context, '/login');
  },
  child: Text('Déconnexion'),
);
```

---

## 📊 Diagramme de Flux

```
┌─────────────────────────────────────────────┐
│           Application Flutter                │
└─────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
  ┌─────▼─────┐         ┌──────▼──────┐
  │ LoginUser │         │LoginSociete │
  │   Page    │         │    Page     │
  └─────┬─────┘         └──────┬──────┘
        │                      │
┌───────▼──────────┐   ┌───────▼─────────────┐
│UserAuthService   │   │SocieteAuthService   │
│  - login()       │   │  - login()          │
│  - register()    │   │  - register()       │
│  - getMe()       │   │  - getMe()          │
└───────┬──────────┘   └───────┬─────────────┘
        │                      │
        └──────────┬───────────┘
                   │
         ┌─────────▼──────────┐
         │ AuthBaseService    │
         │ (Logique commune)  │
         │  - saveToken()     │
         │  - getUserType()   │
         │  - logout()        │
         └─────────┬──────────┘
                   │
         ┌─────────▼──────────┐
         │   ApiService       │
         │  - get()           │
         │  - post()          │
         │  - uploadFile()    │
         └────────────────────┘
                   │
         ┌─────────▼──────────┐
         │  Backend NestJS    │
         │ /auth/login        │
         │ /auth/societe/login│
         └────────────────────┘
```

---

## 🔐 Gestion de l'Authentification

### Stockage Local (SharedPreferences)

```dart
{
  "auth_token": "eyJhbGciOiJIUzI1NiIs...",
  "user_type": "user",  // ou "societe"
  "user_data": {
    "id": 1,
    "nom": "Doe",
    "prenom": "John",
    ...
  }
}
```

### Flux d'Authentification

```
1. User/Societe → login()
2. Backend → Retourne { access_token, user/societe }
3. Service → Sauvegarde token + type + data
4. HomePage → Récupère via getCurrentEntity()
5. Affichage selon le type
```

---

## 📝 Modèles de Données

### UserModel

```dart
class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? photoUrl;
  final String? bio;

  String get fullName => '$prenom $nom';
}
```

### SocieteModel

```dart
class SocieteModel {
  final int id;
  final String nom;
  final String email;
  final String? telephone;
  final String? adresse;
  final String? secteurActivite;
  final String? description;
  final String? logoUrl;
}
```

---

## 🚀 Exemples d'Utilisation

### Connexion User

```dart
final user = await UserAuthService.login(
  identifiant: 'john@example.com',
  password: 'password123',
);
// Token automatiquement sauvegardé
```

### Connexion Societe

```dart
final societe = await SocieteAuthService.login(
  identifiant: 'contact@brakina.bf',
  password: 'password123',
);
// Token automatiquement sauvegardé
```

### Vérifier qui est connecté

```dart
if (await UnifiedAuthService.isUser()) {
  print('C\'est un User');
} else if (await UnifiedAuthService.isSociete()) {
  print('C\'est une Société');
}
```

### Créer un Post

```dart
// Fonctionne pour User ET Societe
final post = await PostService.createPost(
  contenu: 'Mon post',
  visibility: 'public',
);
// Le backend récupère automatiquement l'auteur via JWT
```

---

## ✅ Checklist d'Intégration

### Frontend Flutter
- [x] Services créés (`user_auth_service`, `societe_auth_service`, etc.)
- [x] Modèles définis (`UserModel`, `SocieteModel`)
- [x] Service unifié (`UnifiedAuthService`)
- [x] Exemples de code fournis
- [ ] Intégrer dans les pages de login
- [ ] Intégrer dans HomePage
- [ ] Configurer l'URL de l'API

### Backend NestJS (Déjà fait ✅)
- [x] Routes User (`/auth/register`, `/auth/login`, `/auth/me`)
- [x] Routes Societe (`/auth/societe/register`, etc.)
- [x] Guards JWT (`JwtAuthGuard`, `UserTypeGuard`)
- [x] Decorators (`@CurrentUser`, `@UserType`)

---

---

## 📤 Service d'Upload Média

### Architecture Backend → Flutter

**Backend NestJS** : Module Media séparé
```
POST /media/upload/image
POST /media/upload/video
POST /media/upload/audio
POST /media/upload/document
```

**Flutter** : Service séparé `media_service.dart`

### Pourquoi séparer MediaService et PostService ?

✅ **Réutilisabilité** : Upload pour posts, profils, groupes, messages
✅ **Responsabilité unique** : MediaService = upload, PostService = logique métier
✅ **Testabilité** : Tester l'upload indépendamment
✅ **Cohérence** : Reflète l'architecture backend (module séparé)

### Flux de création de post avec médias

```
1. MediaService.uploadImages([file1, file2])
   → Retourne ['url1', 'url2']

2. PostService.createPost(
     contenu: '...',
     images: ['url1', 'url2']
   )
   → Crée le post avec les URLs
```

**Voir [MEDIA_USAGE_EXAMPLE.md](documentation/MEDIA_USAGE_EXAMPLE.md) pour des exemples détaillés.**

---

## 🎯 Conclusion

Votre backend ayant **2 types d'utilisateurs distincts** avec des **routes séparées** et un **module média séparé**, l'architecture **HYBRIDE + MODULAIRE** est **optimale** :

✅ Code réutilisable (AuthBaseService, MediaService)
✅ Spécialisations claires (UserAuth vs SocieteAuth)
✅ Interface unifiée pour widgets génériques
✅ Séparation des responsabilités (upload vs posts)
✅ Maintenabilité maximale
✅ Évolutif (facile d'ajouter types/modules)

**Prochaine étape** : Intégrer ces services dans vos pages de connexion et HomePage !
