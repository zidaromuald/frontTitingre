# 📦 Documentation de Déploiement - Titingre

Cette documentation couvre le déploiement complet de votre application Flutter sur **Web** et **Android**.

---

## 🚀 Démarrage Rapide

**Commencez ici :** [QUICK_START.md](QUICK_START.md)

Ce guide vous donnera les commandes essentielles pour déployer rapidement.

---

## 📚 Documentation Complète

### 1. [QUICK_START.md](QUICK_START.md)
Guide de démarrage rapide avec les commandes essentielles.

**À lire en premier** - Parfait si vous voulez déployer rapidement sans lire toute la documentation.

### 2. [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
Guide complet de déploiement avec tous les détails.

**Documentation principale** - Contient toutes les étapes détaillées, l'architecture, et les explications complètes.

### 3. [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
Checklist étape par étape pour suivre votre progression.

**Pour suivre votre progression** - Cochez les cases au fur et à mesure que vous avancez.

### 4. [WEB_DEPLOYMENT_VPS.md](WEB_DEPLOYMENT_VPS.md)
Configuration Nginx et SSL détaillée pour le déploiement web.

**Pour le déploiement web** - Configuration complète du VPS, Nginx, SSL, et DNS.

### 5. [ANDROID_PLAYSTORE_SETUP.md](ANDROID_PLAYSTORE_SETUP.md)
Guide complet pour publier sur Google Play Store.

**Pour Android** - Signature, build, assets, et soumission sur Play Console.

### 6. [BACKEND_CORS_CONFIG.md](BACKEND_CORS_CONFIG.md)
Configuration CORS du backend NestJS.

**Configuration backend** - Mise à jour des origines autorisées pour le web.

---

## 🏗️ Architecture

```
VPS Hostinger
├── Backend NestJS → https://api.titingre.com
└── Application Web Flutter → https://www.titingre.com

Play Store
└── Application Mobile Android
    └── Connectée à https://api.titingre.com
```

---

## 🎯 Ordre de lecture recommandé

### Pour un premier déploiement complet :

1. **[QUICK_START.md](QUICK_START.md)** - Vue d'ensemble rapide
2. **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Lire la section "Configuration initiale"
3. **[BACKEND_CORS_CONFIG.md](BACKEND_CORS_CONFIG.md)** - Configurer le backend
4. **[WEB_DEPLOYMENT_VPS.md](WEB_DEPLOYMENT_VPS.md)** - Déployer le web
5. **[ANDROID_PLAYSTORE_SETUP.md](ANDROID_PLAYSTORE_SETUP.md)** - Déployer sur Android
6. **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Vérifier que tout est fait

### Pour une mise à jour web uniquement :

1. **[QUICK_START.md](QUICK_START.md)** - Section "Build Web"
2. **[WEB_DEPLOYMENT_VPS.md](WEB_DEPLOYMENT_VPS.md)** - Section "Mise à jour de l'application"

### Pour une mise à jour Android uniquement :

1. **[QUICK_START.md](QUICK_START.md)** - Section "Build Android"
2. **[ANDROID_PLAYSTORE_SETUP.md](ANDROID_PLAYSTORE_SETUP.md)** - Section "Mises à jour futures"

---

## ⚡ Commandes Rapides

### Build Web
```bash
flutter build web --release --base-href /
```

### Build Android
```bash
flutter build appbundle --release
```

### Déployer Web
```bash
# Configurer d'abord scripts/deploy-web.sh
./scripts/deploy-web.sh
```

---

## 🔗 URLs Importantes

- **Backend API** : https://api.titingre.com
- **Application Web** : https://www.titingre.com
- **Site Web** : https://titingre.com
- **Play Console** : https://play.google.com/console

---

## 📞 Support

En cas de problème, consultez :
- Section "Dépannage" dans [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Section "Problèmes courants" dans [QUICK_START.md](QUICK_START.md)

---

## ✅ Prérequis

- [ ] Flutter SDK installé
- [ ] Accès au VPS Hostinger
- [ ] Compte Firebase configuré
- [ ] Compte Google Play Console (pour Android)
- [ ] Domaines configurés (titingre.com, www.titingre.com, api.titingre.com)

---

**Documentation mise à jour le** : 2026-01-07

**Version de l'application** : 1.0.0
