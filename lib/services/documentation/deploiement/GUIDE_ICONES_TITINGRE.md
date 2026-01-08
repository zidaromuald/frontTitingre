# Guide de Création des Icônes pour Titingre

## 📱 Icônes requises pour l'application

### Pour le Web (déjà configuré)
- `web/favicon.png` - 32x32px ou 48x48px
- `web/icons/Icon-192.png` - 192x192px
- `web/icons/Icon-512.png` - 512x512px
- `web/icons/Icon-maskable-192.png` - 192x192px (avec zone de sécurité)
- `web/icons/Icon-maskable-512.png` - 512x512px (avec zone de sécurité)

### Pour Android
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_foreground.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_round.png`

### Pour iOS
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

## 🎨 Spécifications de Design

### Couleur Principale
- **Orange Titingre**: `#FF6B35` (défini dans manifest.json)
- **Fond blanc**: `#FFFFFF`

### Recommandations
1. Logo simple et reconnaissable
2. Bon contraste avec le fond
3. Éviter les textes trop petits
4. Tester sur fond clair et foncé

## 🛠️ Méthode 1 : Utiliser flutter_launcher_icons (Recommandé)

### Étape 1 : Installer le package

Ajoutez dans `pubspec.yaml` :

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### Étape 2 : Configurer les icônes

Ajoutez dans `pubspec.yaml` :

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  web:
    generate: true
    background_color: "#FFFFFF"
    theme_color: "#FF6B35"
  image_path: "assets/icon/titingre_logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/titingre_logo_foreground.png"
```

### Étape 3 : Préparer vos images sources

Créez le dossier `assets/icon/` et ajoutez :

1. **titingre_logo.png** (1024x1024px)
   - Logo complet avec fond
   - Format PNG avec transparence

2. **titingre_logo_foreground.png** (1024x1024px)
   - Uniquement le logo (sans fond)
   - Pour les icônes adaptatives Android
   - Centré avec marge de sécurité de 20%

### Étape 4 : Générer les icônes

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 🎨 Méthode 2 : Outils en ligne

### Outils recommandés

1. **App Icon Generator** - https://www.appicon.co/
   - Upload votre logo 1024x1024px
   - Génère tous les formats automatiquement
   - Téléchargez et remplacez les fichiers

2. **Figma / Canva**
   - Créez votre logo
   - Exportez en 1024x1024px
   - Utilisez la Méthode 1

3. **PWA Asset Generator** - https://github.com/elegantapp/pwa-asset-generator
   ```bash
   npx pwa-asset-generator assets/icon/titingre_logo.png web/icons
   ```

## 📐 Zones de Sécurité pour Icônes Maskable

Pour les icônes maskable (Android), respectez ces marges :

```
┌─────────────────────────┐
│   Zone de découpe       │
│  ┌───────────────────┐  │
│  │                   │  │
│  │   Zone visible    │  │
│  │   (80% centre)    │  │
│  │                   │  │
│  │  Logo ici         │  │
│  │                   │  │
│  └───────────────────┘  │
│   Marge de sécurité     │
└─────────────────────────┘
```

- **Zone totale**: 512x512px
- **Zone de sécurité**: Garder le logo dans les 410x410px centraux (80%)
- **Fond**: Blanc (#FFFFFF) ou transparent

## 🖼️ Template de Logo Titingre (Suggestion)

Si vous n'avez pas encore de logo, voici une suggestion simple :

```
┌─────────────────────────┐
│                         │
│       T T              │
│      T   T             │
│       T T              │
│                         │
│     TITINGRE           │
│                         │
└─────────────────────────┘
```

Ou utilisez :
- Initiale "T" stylisée
- Couleur orange (#FF6B35)
- Fond blanc ou transparent
- Police moderne (Montserrat, Poppins, etc.)

## ✅ Checklist avant déploiement

- [ ] Logo créé en 1024x1024px
- [ ] Icônes web générées (192px, 512px)
- [ ] Favicon.png créé (48x48px)
- [ ] Icônes Android générées (si applicable)
- [ ] Icônes iOS générées (si applicable)
- [ ] Test sur fond clair et foncé
- [ ] Vérification de la lisibilité en petite taille

## 🚀 Après avoir généré les icônes

1. **Vérifier les fichiers** :
   ```bash
   dir web\icons
   ```

2. **Rebuild l'application** :
   ```bash
   flutter clean
   flutter build web --release --base-href /
   ```

3. **Tester localement** :
   ```bash
   flutter run -d chrome
   ```

4. **Déployer** selon [WEB_DEPLOYMENT_VPS.md](lib/services/documentation/deploiement/WEB_DEPLOYMENT_VPS.md)

## 🎯 Résultat attendu

Après configuration, vous aurez :
- ✅ Nom "Titingre" partout
- ✅ Couleur thème orange (#FF6B35)
- ✅ Icônes personnalisées
- ✅ PWA installable
- ✅ Prêt pour production

## 📞 Besoin d'aide ?

Si vous avez besoin d'aide pour créer le logo :
1. Fournir une image/esquisse du logo souhaité
2. Ou utiliser un service comme Canva/Figma
3. Ou engager un designer sur Fiverr/Upwork
