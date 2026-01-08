# Guide de Déploiement Complet - Titingre

Ce guide couvre le déploiement de votre application Flutter sur **trois plateformes** :
- 📱 Application mobile Android (Google Play Store)
- 🌐 Application Web (VPS Hostinger)
- 🔧 Backend NestJS (déjà sur VPS)

## 📋 Table des matières

1. [Vue d'ensemble de l'architecture](#architecture)
2. [Prérequis](#prérequis)
3. [Configuration initiale](#configuration-initiale)
4. [Déploiement Web](#déploiement-web)
5. [Déploiement Android](#déploiement-android)
6. [Maintenance et mises à jour](#maintenance)
7. [Dépannage](#dépannage)

---

## 🏗️ Architecture {#architecture}

```
┌─────────────────────────────────────────────────────────────┐
│                    VPS Hostinger                            │
│                                                             │
│  ┌──────────────────┐        ┌─────────────────────┐      │
│  │  Backend NestJS  │        │  Application Web    │      │
│  │  Port: 3000      │        │  Flutter            │      │
│  │  api.titingre.com│        │  www.titingre.com   │      │
│  └──────────────────┘        └─────────────────────┘      │
│           ▲                            ▲                    │
│           │                            │                    │
│           └────────── Nginx ───────────┘                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                        ▲
                        │
        ┌───────────────┴───────────────┐
        │                               │
┌───────▼────────┐            ┌────────▼─────────┐
│  App Mobile    │            │  Navigateur Web  │
│  Android/iOS   │            │  Chrome/Safari   │
│  (Play Store)  │            │                  │
└────────────────┘            └──────────────────┘
```

### URLs et domaines

- **Backend API** : `https://api.titingre.com`
- **Application Web** : `https://www.titingre.com`
- **Site Web** : `https://titingre.com`
- **Mobile** : Connexion directe à `https://api.titingre.com`

---

## ✅ Prérequis {#prérequis}

### Pour tous les déploiements

- [ ] Flutter SDK installé (version 3.x)
- [ ] Compte Firebase configuré
- [ ] Accès au VPS Hostinger
- [ ] Domaines configurés (titingre.com, api.titingre.com, www.titingre.com)

### Pour Android

- [ ] Compte Google Play Console (99$ unique)
- [ ] Android Studio ou JDK installé (pour keytool)
- [ ] Certificat de signature créé

### Pour Web

- [ ] Nginx installé sur le VPS
- [ ] Certbot configuré (Let's Encrypt)
- [ ] Accès SSH au VPS

---

## ⚙️ Configuration initiale {#configuration-initiale}

### 1. Mise à jour du code Flutter

Le code a déjà été mis à jour avec :
- ✅ Configuration multi-plateforme dans [lib/config/app_config.dart](lib/config/app_config.dart)
- ✅ ApiService adapté dans [lib/services/api_service.dart](lib/services/api_service.dart)

### 2. Configuration du Backend (CORS)

Sur votre VPS, mettez à jour le fichier `.env` :

```bash
# Se connecter au VPS
ssh user@votre-vps-ip

# Éditer le fichier .env du backend
nano /path/to/backend/.env

# Ajouter www.titingre.com aux origines autorisées
ALLOWED_ORIGINS=https://titingre.com,https://www.titingre.com,https://api.titingre.com,https://www.titingre.com

# Sauvegarder et redémarrer le backend
pm2 restart your-backend-app
```

Voir [BACKEND_CORS_CONFIG.md](BACKEND_CORS_CONFIG.md) pour plus de détails.

### 3. Configuration Firebase

Assurez-vous que Firebase est configuré pour :
- **Web** : Ajoutez l'application web dans Firebase Console
- **Android** : Téléchargez `google-services.json` et placez-le dans `android/app/`

---

## 🌐 Déploiement Web {#déploiement-web}

### Étape 1 : Build de l'application

**Windows :**
```batch
cd c:\Projets\titingre\gestauth_clean
scripts\build-web.bat
```

**Linux/Mac/Git Bash :**
```bash
cd /path/to/gestauth_clean
flutter clean
flutter pub get
flutter build web --release --base-href /
```

### Étape 2 : Configuration du VPS

1. **Créer le répertoire web**
```bash
ssh user@votre-vps-ip
sudo mkdir -p /var/www/www.titingre.com
sudo chown -R $USER:$USER /var/www/www.titingre.com
```

2. **Configurer Nginx**

Voir le fichier [WEB_DEPLOYMENT_VPS.md](WEB_DEPLOYMENT_VPS.md) pour :
- Configuration complète de Nginx
- Configuration SSL avec Let's Encrypt
- Optimisations de performance

3. **Configurer DNS**

Dans votre panneau Hostinger :
```
Type: A
Nom: app
Valeur: [IP-DE-VOTRE-VPS]
TTL: 14400
```

### Étape 3 : Déploiement

**Méthode 1 : Via script (recommandé)**
```bash
# Éditer le script avec vos informations
nano scripts/deploy-web.sh

# Modifier :
VPS_USER="votre_username"
VPS_IP="votre_vps_ip"

# Rendre exécutable
chmod +x scripts/deploy-web.sh

# Exécuter
./scripts/deploy-web.sh
```

**Méthode 2 : Manuellement avec SCP**
```bash
scp -r build/web/* user@votre-vps-ip:/var/www/www.titingre.com/
```

**Méthode 3 : Via SFTP (FileZilla/WinSCP)**
1. Connectez-vous au VPS via SFTP
2. Naviguez vers `/var/www/www.titingre.com/`
3. Uploadez tout le contenu de `build/web/`

### Étape 4 : Vérification

1. Accédez à `https://www.titingre.com`
2. Vérifiez les logs : `ssh user@vps "sudo tail -f /var/log/nginx/www.titingre.com.access.log"`
3. Testez les fonctionnalités principales

---

## 📱 Déploiement Android {#déploiement-android}

### Étape 1 : Configuration Android

Voir [ANDROID_PLAYSTORE_SETUP.md](ANDROID_PLAYSTORE_SETUP.md) pour :
- Configuration complète de build.gradle
- Création de la clé de signature
- Configuration des permissions

### Étape 2 : Créer la clé de signature

```bash
keytool -genkey -v -keystore c:\Users\VOTRE_NOM\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

⚠️ **IMPORTANT** : Sauvegardez le fichier `.jks` et les mots de passe !

### Étape 3 : Configurer key.properties

Créez `android/key.properties` :
```properties
storePassword=VOTRE_STORE_PASSWORD
keyPassword=VOTRE_KEY_PASSWORD
keyAlias=upload
storeFile=C:\\Users\\VOTRE_NOM\\upload-keystore.jks
```

⚠️ Ajoutez `android/key.properties` au `.gitignore` !

### Étape 4 : Build de l'application

**Windows :**
```batch
scripts\build-android.bat
```

**Linux/Mac :**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Les fichiers générés :
- **App Bundle** (Play Store) : `build/app/outputs/bundle/release/app-release.aab`
- **APK** (Tests) : `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Étape 5 : Préparer les assets

#### Icône (512x512 px)
Créez une icône PNG haute qualité.

#### Screenshots
- Minimum 2 screenshots par format
- Résolution : 1080x1920 ou 1920x1080
- Utilisez un émulateur ou appareil réel

#### Feature Graphic (1024x500 px)
Image promotionnelle pour le Store.

### Étape 6 : Google Play Console

1. **Créer l'application**
   - Allez sur [play.google.com/console](https://play.google.com/console)
   - Créez une nouvelle application
   - Choisissez la langue par défaut

2. **Fiche du Store**
   - Description courte (80 caractères max)
   - Description complète (4000 caractères max)
   - Screenshots et graphiques

3. **Classification du contenu**
   - Remplissez le questionnaire
   - Obtenez une classification

4. **Prix et distribution**
   - Gratuite ou payante
   - Pays de distribution
   - URL politique de confidentialité

5. **Créer une version**
   - Production → Nouvelle version
   - Uploadez `app-release.aab`
   - Notes de version
   - Soumettre pour examen

### Délai de révision

- **Première soumission** : 7-14 jours
- **Mises à jour** : 1-3 jours

---

## 🔄 Maintenance et mises à jour {#maintenance}

### Mise à jour de l'application Web

```bash
# 1. Build
flutter build web --release

# 2. Déployer
./scripts/deploy-web.sh

# 3. Vérifier
curl -I https://www.titingre.com
```

### Mise à jour Android

1. **Incrémenter la version** dans `android/app/build.gradle` :
```gradle
defaultConfig {
    versionCode 2        // Incrémenter
    versionName "1.0.1"  // Nouvelle version
}
```

2. **Build et upload**
```bash
flutter build appbundle --release
# Uploader sur Play Console → Nouvelle version
```

### Monitoring

**Logs Nginx (Web)**
```bash
ssh user@vps "sudo tail -f /var/log/nginx/www.titingre.com.access.log"
ssh user@vps "sudo tail -f /var/log/nginx/www.titingre.com.error.log"
```

**Logs Backend**
```bash
ssh user@vps "pm2 logs your-backend-app"
```

**Play Console (Android)**
- Rapports de crash
- Statistiques d'utilisation
- Avis utilisateurs

---

## 🔧 Dépannage {#dépannage}

### Web : L'application ne charge pas

1. **Vérifier Nginx**
```bash
sudo nginx -t
sudo systemctl status nginx
```

2. **Vérifier les permissions**
```bash
ls -la /var/www/www.titingre.com
```

3. **Vérifier les CORS**
```bash
curl -I -X OPTIONS https://api.titingre.com/health \
  -H "Origin: https://www.titingre.com"
```

### Web : Erreur 502 Bad Gateway

Le backend NestJS n'est pas accessible :
```bash
pm2 status
pm2 restart your-backend-app
```

### Android : Erreur de signature

Vérifiez `android/key.properties` :
- Chemins corrects
- Mots de passe corrects
- Fichier `.jks` existe

### Android : Build échoue

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build appbundle --release
```

### API non accessible depuis mobile

Vérifiez :
1. `https://api.titingre.com` est accessible
2. Certificat SSL valide
3. CORS configuré correctement
4. Permissions réseau dans AndroidManifest.xml

---

## 📞 Support

Pour toute question :
1. Consultez les fichiers de documentation détaillés
2. Vérifiez les logs (Nginx, Backend, Play Console)
3. Testez sur différents environnements

---

## 📁 Fichiers de référence

- [app_config.dart](lib/config/app_config.dart) - Configuration multi-plateforme
- [api_service.dart](lib/services/api_service.dart) - Service API
- [WEB_DEPLOYMENT_VPS.md](WEB_DEPLOYMENT_VPS.md) - Déploiement web détaillé
- [ANDROID_PLAYSTORE_SETUP.md](ANDROID_PLAYSTORE_SETUP.md) - Configuration Android détaillée
- [BACKEND_CORS_CONFIG.md](BACKEND_CORS_CONFIG.md) - Configuration CORS backend

---

## ✅ Checklist finale

### Avant le premier déploiement

- [ ] Backend CORS mis à jour
- [ ] DNS configurés (www.titingre.com)
- [ ] Certificats SSL obtenus
- [ ] Firebase configuré (Web + Android)
- [ ] Clé de signature Android créée
- [ ] Politique de confidentialité publiée

### Web
- [ ] Build réussi
- [ ] Nginx configuré
- [ ] Fichiers transférés
- [ ] Application accessible
- [ ] API fonctionne

### Android
- [ ] Build réussi (.aab généré)
- [ ] APK testé sur appareil
- [ ] Screenshots créés
- [ ] Fiche Play Store complétée
- [ ] Application soumise

---

**Bonne chance avec vos déploiements ! 🚀**
