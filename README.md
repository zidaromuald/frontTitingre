# Titingre - Application Flutter Multi-plateforme

Application de réseau social professionnel développée avec Flutter, déployable sur Web et Mobile (Android/iOS).

---

## 🚀 Démarrage Rapide

### Installation

```bash
# Cloner le projet
git clone [url-du-repo]
cd gestauth_clean

# Installer les dépendances
flutter pub get

# Lancer en mode développement
flutter run
```

### Développement

```bash
# Web
flutter run -d chrome

# Android
flutter run

# iOS
flutter run -d ios
```

---

## 📦 Déploiement

### Pour déployer l'application :

📖 **Consultez la [Documentation de Déploiement](lib/services/documentation/deploiement/README.md)**

**Guides disponibles :**
- [Guide de démarrage rapide](lib/services/documentation/deploiement/QUICK_START.md)
- [Guide complet de déploiement](lib/services/documentation/deploiement/DEPLOYMENT_GUIDE.md)
- [Déploiement Web sur VPS](lib/services/documentation/deploiement/WEB_DEPLOYMENT_VPS.md)
- [Publication Android sur Play Store](lib/services/documentation/deploiement/ANDROID_PLAYSTORE_SETUP.md)

### Build rapide

```bash
# Web (production)
flutter build web --release --base-href /

# Android (App Bundle pour Play Store)
flutter build appbundle --release

# Android (APK pour tests)
flutter build apk --release --split-per-abi
```

---

## 🏗️ Architecture

```
Application Flutter
├── Web → https://www.titingre.com (VPS Hostinger)
├── Android → Google Play Store
├── iOS → App Store (à venir)
└── Backend API → https://api.titingre.com
```

### Technologies

- **Framework** : Flutter 3.x
- **Langage** : Dart
- **Backend** : NestJS (Node.js)
- **Base de données** : PostgreSQL
- **Authentification** : Firebase Auth
- **Stockage** : Cloudflare R2
- **Hébergement** : VPS Hostinger (Backend + Web)

---

## 📁 Structure du Projet

```
lib/
├── config/              # Configuration de l'application
│   └── app_config.dart  # Configuration multi-plateforme
├── is/                  # Pages Inscription Société
├── iu/                  # Pages Inscription Utilisateur
├── services/            # Services et logique métier
│   ├── api_service.dart       # Service API principal
│   ├── media_service.dart     # Gestion des médias
│   └── documentation/         # Documentation complète
│       ├── INDEX.md           # Index de la documentation
│       ├── deploiement/       # Guides de déploiement
│       ├── architecture/      # Documentation architecture
│       └── ...
├── widgets/             # Composants réutilisables
└── main.dart           # Point d'entrée de l'application

scripts/
├── build-web.bat       # Script de build Web (Windows)
├── build-android.bat   # Script de build Android (Windows)
└── deploy-web.sh       # Script de déploiement Web (Linux/Mac)
```

---

## 🔧 Configuration

### Variables d'environnement

La configuration se trouve dans [`lib/config/app_config.dart`](lib/config/app_config.dart) :

```dart
static String get apiBaseUrl => 'https://api.titingre.com';
static String get webAppUrl => 'https://www.titingre.com';
static String get websiteUrl => 'https://titingre.com';
```

### Firebase

1. Téléchargez `google-services.json` depuis Firebase Console
2. Placez-le dans `android/app/google-services.json`
3. Pour iOS : `ios/Runner/GoogleService-Info.plist`

### Backend

Le backend est configuré séparément. Voir [BACKEND_CORS_CONFIG.md](lib/services/documentation/deploiement/BACKEND_CORS_CONFIG.md)

---

## 📚 Documentation

### Documentation Complète

📖 **[Index de la Documentation](lib/services/documentation/INDEX.md)**

### Guides Principaux

1. **[Guide de Déploiement](lib/services/documentation/deploiement/README.md)**
   - Déploiement Web sur VPS
   - Publication Android sur Play Store
   - Configuration Backend

2. **[Architecture](lib/services/documentation/architecture/)**
   - Architecture des services
   - Flux de données
   - Patterns utilisés

3. **[Exemples](lib/services/documentation/)**
   - Exemples d'utilisation des services
   - Gestion des médias
   - Upload de fichiers

---

## 🛠️ Scripts Disponibles

### Windows (`.bat`)

```bash
# Build Web
scripts\build-web.bat

# Build Android
scripts\build-android.bat

# Déployer Web (guide manuel)
scripts\deploy-web.bat
```

### Linux/Mac (`.sh`)

```bash
# Déployer Web
chmod +x scripts/deploy-web.sh
./scripts/deploy-web.sh
```

---

## 🔗 URLs

- **Application Web** : https://www.titingre.com
- **Site Web** : https://titingre.com
- **Backend API** : https://api.titingre.com
- **Firebase Console** : https://console.firebase.google.com
- **Play Console** : https://play.google.com/console

---

## 🧪 Tests

```bash
# Exécuter les tests
flutter test

# Tests avec couverture
flutter test --coverage
```

---

## 📝 Dépendances Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                      # Requêtes HTTP
  shared_preferences: ^2.2.2        # Stockage local
  firebase_core: ^3.8.1             # Firebase
  firebase_auth: ^5.3.3             # Authentification
  cached_network_image: ^3.3.1      # Images optimisées
  flutter_image_compress: ^2.3.0    # Compression d'images
  image_picker: ^1.0.4              # Sélection de photos
  permission_handler: ^11.0.1       # Permissions
```

Voir [`pubspec.yaml`](pubspec.yaml) pour la liste complète.

---

## 🤝 Contribution

1. Fork le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

---

## 📄 License

Ce projet est privé et propriétaire.

---

## 📞 Support

Pour toute question :

- **Documentation** : Voir [lib/services/documentation/INDEX.md](lib/services/documentation/INDEX.md)
- **Déploiement** : Voir [lib/services/documentation/deploiement/README.md](lib/services/documentation/deploiement/README.md)
- **Issues** : Créer une issue dans le repository

---

## 📊 Statut du Projet

**Version actuelle** : 1.0.0

**Plateformes supportées** :
- ✅ Web
- ✅ Android
- 🚧 iOS (en cours)

**Déploiements** :
- ✅ Backend API (Production)
- 🚧 Application Web (En préparation)
- 🚧 Application Android (En préparation)

---

## 🎯 Roadmap

- [ ] Déploiement Web sur VPS
- [ ] Publication Android sur Play Store
- [ ] Support iOS
- [ ] Notifications push
- [ ] Mode hors ligne
- [ ] Tests automatisés
- [ ] CI/CD Pipeline

---

**Développé avec ❤️ par l'équipe Titingre**
