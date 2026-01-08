# 🚀 Guide de démarrage rapide - Déploiement Titingre

## Pour déployer rapidement, suivez ces étapes :

### 1️⃣ Déploiement Web (VPS Hostinger)

```bash
# Build l'application web
scripts\build-web.bat

# Configurer vos informations VPS dans :
scripts\deploy-web.sh

# Déployer
.\scripts\deploy-web.sh
```

**URL finale** : https://www.titingre.com

---

### 2️⃣ Déploiement Android (Play Store)

```bash
# 1. Créer la clé de signature (UNE SEULE FOIS)
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Créer android/key.properties avec vos mots de passe
# Voir ANDROID_PLAYSTORE_SETUP.md

# 3. Build l'application
scripts\build-android.bat

# 4. Uploader sur Play Console
# Fichier : build\app\outputs\bundle\release\app-release.aab
```

---

### 3️⃣ Configuration Backend (À faire UNE SEULE FOIS)

Sur votre VPS :

```bash
# Éditer le .env du backend
nano /path/to/backend/.env

# Ajouter cette ligne :
ALLOWED_ORIGINS=https://titingre.com,https://www.titingre.com

# Redémarrer le backend
pm2 restart your-backend-app
```

---

## 📚 Documentation complète

Pour plus de détails, consultez :

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Guide complet de déploiement
- **[WEB_DEPLOYMENT_VPS.md](WEB_DEPLOYMENT_VPS.md)** - Déploiement web détaillé
- **[ANDROID_PLAYSTORE_SETUP.md](ANDROID_PLAYSTORE_SETUP.md)** - Configuration Android détaillée
- **[BACKEND_CORS_CONFIG.md](BACKEND_CORS_CONFIG.md)** - Configuration backend

---

## ⚡ Commandes essentielles

### Build Web
```bash
flutter build web --release --base-href /
```

### Build Android (App Bundle)
```bash
flutter build appbundle --release
```

### Build Android (APK pour tests)
```bash
flutter build apk --release --split-per-abi
```

---

## 🆘 Problèmes courants

### L'application web ne se connecte pas à l'API
➡️ Vérifiez les CORS dans le backend (voir [BACKEND_CORS_CONFIG.md](BACKEND_CORS_CONFIG.md))

### Build Android échoue
➡️ Vérifiez [android/key.properties](android/key.properties) et que le fichier `.jks` existe

### Erreur 502 sur le web
➡️ Le backend est probablement arrêté : `pm2 restart your-backend-app`

---

## 📞 Checklist avant déploiement

### Web
- [ ] DNS configuré (www.titingre.com → IP VPS)
- [ ] Nginx configuré sur le VPS
- [ ] Certificat SSL obtenu (Let's Encrypt)
- [ ] CORS backend mis à jour avec les origines web

### Android
- [ ] Clé de signature créée (.jks)
- [ ] key.properties configuré
- [ ] google-services.json dans android/app/
- [ ] Compte Google Play Console actif
- [ ] Screenshots et assets prêts

---

**Tout est prêt ! Suivez les étapes ci-dessus pour déployer votre application. 🎉**
