# 🚀 Démarrage Rapide du Déploiement

**Tout est prêt pour le déploiement !** Suivez ces étapes simples.

---

## 📋 Avant de commencer

✅ **Configuration effectuée** :
- Configuration multi-plateforme dans `lib/config/app_config.dart`
- Service API adapté
- Scripts de build créés
- Documentation complète disponible

✅ **URLs configurées** :
- Backend : `https://api.titingre.com`
- Web : `https://www.titingre.com`
- Site : `https://titingre.com`

---

## 🌐 OPTION 1 : Déployer le Web

### Étape 1 : Build
```bash
scripts\build-web.bat
```

### Étape 2 : Configurer le VPS
Suivez : [WEB_DEPLOYMENT_VPS.md](lib/services/documentation/deploiement/WEB_DEPLOYMENT_VPS.md)

### Étape 3 : Déployer
```bash
# Configurer vos infos dans scripts/deploy-web.sh
./scripts/deploy-web.sh
```

**URL finale** : https://www.titingre.com

---

## 📱 OPTION 2 : Déployer Android

### Étape 1 : Créer la clé (une seule fois)
```bash
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Étape 2 : Configurer key.properties
Suivez : [ANDROID_PLAYSTORE_SETUP.md](lib/services/documentation/deploiement/ANDROID_PLAYSTORE_SETUP.md)

### Étape 3 : Build
```bash
scripts\build-android.bat
```

### Étape 4 : Upload sur Play Console
Fichier : `build\app\outputs\bundle\release\app-release.aab`

---

## 📚 Documentation Complète

**Commencez par** : [QUICK_START.md](lib/services/documentation/deploiement/QUICK_START.md)

**Tous les guides** :
- [README.md](README.md) - Documentation principale
- [QUICK_START.md](lib/services/documentation/deploiement/QUICK_START.md) - Guide rapide
- [DEPLOYMENT_GUIDE.md](lib/services/documentation/deploiement/DEPLOYMENT_GUIDE.md) - Guide complet
- [DEPLOYMENT_CHECKLIST.md](lib/services/documentation/deploiement/DEPLOYMENT_CHECKLIST.md) - Checklist
- [MODIFICATIONS_DEPLOIEMENT.md](MODIFICATIONS_DEPLOIEMENT.md) - Récapitulatif modifications

---

## 🔧 Configuration Backend

Sur votre VPS, mettez à jour :
```bash
nano /path/to/backend/.env
```

Ajouter :
```env
ALLOWED_ORIGINS=https://titingre.com,https://www.titingre.com,https://api.titingre.com
```

Redémarrer :
```bash
pm2 restart your-backend-app
```

---

## 📞 Besoin d'aide ?

- **Web** → [WEB_DEPLOYMENT_VPS.md](lib/services/documentation/deploiement/WEB_DEPLOYMENT_VPS.md)
- **Android** → [ANDROID_PLAYSTORE_SETUP.md](lib/services/documentation/deploiement/ANDROID_PLAYSTORE_SETUP.md)
- **Backend** → [BACKEND_CORS_CONFIG.md](lib/services/documentation/deploiement/BACKEND_CORS_CONFIG.md)

---

**C'est parti ! 🎉**
