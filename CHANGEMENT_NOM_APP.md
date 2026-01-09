# Changement du Nom de l'Application - Titingre

**Date:** 2026-01-09
**Commit:** 4dbc7fe

---

## ✅ Modifications Effectuées

Le nom de l'application a été changé de **"gestauth_clean"** à **"Titingre"** sur les plateformes mobiles.

### 1. Android

**Fichier:** [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml)

```xml
<!-- AVANT -->
<application
    android:label="gestauth_clean"
    ...>

<!-- APRÈS -->
<application
    android:label="Titingre"
    ...>
```

**Résultat:** Le nom affiché sous l'icône de l'app Android sera "Titingre"

---

### 2. iOS

**Fichier:** [ios/Runner/Info.plist](ios/Runner/Info.plist)

```xml
<!-- AVANT -->
<key>CFBundleDisplayName</key>
<string>Gestauth Clean</string>
...
<key>CFBundleName</key>
<string>gestauth_clean</string>

<!-- APRÈS -->
<key>CFBundleDisplayName</key>
<string>Titingre</string>
...
<key>CFBundleName</key>
<string>Titingre</string>
```

**Résultat:** Le nom affiché sous l'icône de l'app iOS sera "Titingre"

---

### 3. Description du Projet

**Fichier:** [pubspec.yaml](pubspec.yaml)

```yaml
# AVANT
description: "A new Flutter project."

# APRÈS
description: "Titingre - Application de gestion d'authentification et de réseau social"
```

---

## 🧪 Comment Tester

### Option 1: Tester sur Émulateur/Simulateur

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Après installation, regardez le nom sous l'icône
```

### Option 2: Build et Installation

**Android:**
```bash
flutter build apk --release
# ou
flutter build appbundle --release

# Installez l'APK et vérifiez le nom dans le launcher
```

**iOS:**
```bash
flutter build ios --release

# Déployez via Xcode et vérifiez le nom sur l'écran d'accueil
```

---

## 📱 Résultat Attendu

Après ces modifications, l'application s'affichera comme:

| Plateforme | Ancien Nom | Nouveau Nom |
|------------|------------|-------------|
| **Android** | gestauth_clean | **Titingre** |
| **iOS** | Gestauth Clean | **Titingre** |
| **Web** | (inchangé) | (inchangé) |

---

## ⚠️ Notes Importantes

### 1. **Le nom du package reste inchangé**

Le nom technique du package (`gestauth_clean`) dans `pubspec.yaml` reste le même. Seul le **nom affiché** à l'utilisateur a changé.

```yaml
name: gestauth_clean  # ← NE PAS CHANGER (nom technique)
description: "Titingre..."  # ← Changé (description)
```

**Pourquoi ne pas changer le nom du package?**
- Changer le nom du package nécessite de renommer tous les imports dans le code
- Cela affecterait le bundle identifier sur iOS et Android
- Cela pourrait casser les configurations Firebase, notifications, etc.

### 2. **Clean et Rebuild Recommandés**

Après ces modifications, il est recommandé de nettoyer les builds:

```bash
flutter clean
flutter pub get
flutter run
```

### 3. **Déploiement Production**

Quand vous déployez sur les stores:
- **Google Play Store**: Le nom affiché sera "Titingre"
- **Apple App Store**: Le nom affiché sera "Titingre"
- Vous pouvez utiliser un nom différent sur les stores si besoin (configuré dans les consoles respectives)

---

## 🔄 Pour Annuler (si nécessaire)

Si vous souhaitez revenir à l'ancien nom:

```bash
git revert 4dbc7fe
```

Ou modifiez manuellement:
- `AndroidManifest.xml`: `android:label="gestauth_clean"`
- `Info.plist`: `CFBundleDisplayName` et `CFBundleName` à `"gestauth_clean"`

---

## 📋 Checklist de Vérification

Après avoir appliqué ces changements:

- [x] AndroidManifest.xml modifié
- [x] Info.plist modifié
- [x] pubspec.yaml modifié
- [x] Commit créé (4dbc7fe)
- [ ] `flutter clean` exécuté
- [ ] `flutter pub get` exécuté
- [ ] App testée sur Android
- [ ] App testée sur iOS
- [ ] Nom vérifié sur l'écran d'accueil

---

## 🎯 Prochaines Étapes (Optionnel)

Si vous souhaitez personnaliser davantage:

1. **Modifier le package name** (complexe, nécessite refactoring complet)
2. **Changer l'icône de l'app** (déjà configuré avec flutter_launcher_icons)
3. **Personnaliser le splash screen**
4. **Configurer les métadonnées des stores**

---

**Dernière mise à jour:** 2026-01-09
**Auteur:** Équipe Titingre
