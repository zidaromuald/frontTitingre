# Harmonisation des Couleurs - Profil IS et IU

**Date:** 2026-01-09
**Commit:** ca61dbc

---

## 🎨 Problème Identifié

Le profil société IS utilisait des couleurs différentes du profil utilisateur IU:
- **Profil IS**: Couleur principale verte `Color(0xff5ac18e)`
- **Profil IU**: Couleur principale bleue `Color(0xFF1E4A8C)` (Mattermost Blue)

Cela créait une **incohérence visuelle** entre les deux interfaces.

---

## ✅ Modifications Effectuées

### 1. Remplacement de la Palette de Couleurs

**Avant (Profil IS):**
```dart
static const Color primaryColor = Color(0xff5ac18e); // Vert
```

**Après (Profil IS):**
```dart
// Couleurs (même style que profil IU)
static const Color mattermostBlue = Color(0xFF1E4A8C);
static const Color mattermostGreen = Color(0xFF28A745);
static const Color mattermostGray = Color(0xFFF4F4F4);
```

### 2. Remplacement de Toutes les Références

Toutes les occurrences de `primaryColor` ont été remplacées par `mattermostBlue`:

| Élément | Ancienne Couleur | Nouvelle Couleur |
|---------|------------------|------------------|
| **AppBar background** | `primaryColor` (vert) | `mattermostBlue` |
| **TextField focusedBorder** | `primaryColor` (vert) | `mattermostBlue` |
| **Avatar borderColor** | `primaryColor` (vert) | `mattermostBlue` |
| **Chip section (produits)** | `primaryColor` (vert) | `mattermostBlue` |
| **Scaffold background** | `Colors.grey[100]` | `mattermostGray` |
| **SnackBar succès** | `primaryColor` (vert) | `mattermostGreen` |

### 3. Titre de l'AppBar Cohérent

**Avant:**
- Écran de chargement: "Mon Profil"
- Écran principal: "Mon Profil Société"

**Après:**
- **Tous les écrans**: "Mon Profil Société"

---

## 📊 Résultat

### Profil Utilisateur IU
```dart
// Couleurs
static const Color mattermostBlue = Color(0xFF1E4A8C);
static const Color mattermostGreen = Color(0xFF28A745);
static const Color mattermostGray = Color(0xFFF4F4F4);

// AppBar
AppBar(
  backgroundColor: mattermostBlue,
  title: Text("Mon Profil"),
)

// Background
Scaffold(backgroundColor: mattermostGray)
```

### Profil Société IS (maintenant identique)
```dart
// Couleurs
static const Color mattermostBlue = Color(0xFF1E4A8C);
static const Color mattermostGreen = Color(0xFF28A745);
static const Color mattermostGray = Color(0xFFF4F4F4);

// AppBar
AppBar(
  backgroundColor: mattermostBlue,
  title: Text("Mon Profil Société"),
)

// Background
Scaffold(backgroundColor: mattermostGray)
```

---

## 🎯 Avantages de cette Harmonisation

1. **Cohérence visuelle** entre IU et IS
2. **Identité visuelle unifiée** de l'application Titingre
3. **Meilleure expérience utilisateur** (pas de confusion)
4. **Facilité de maintenance** (une seule palette de couleurs)
5. **Conformité aux guidelines Mattermost** (design system établi)

---

## 🧪 Comment Vérifier

### Test Visuel

1. **Connectez-vous en tant qu'utilisateur** (IU)
   - Allez dans **Paramètres > Mon Profil**
   - Notez la couleur bleue de l'AppBar

2. **Connectez-vous en tant que société** (IS)
   - Allez dans **Paramètres > Mon Profil Société**
   - Vérifiez que l'AppBar est de la **même couleur bleue**

3. **Comparez:**
   - AppBar: Bleu identique ✅
   - Background: Gris clair identique ✅
   - Champs de texte focus: Bordure bleue identique ✅
   - Message succès: Vert identique ✅

---

## 📝 Détails Techniques

### Fichiers Modifiés

- [lib/is/onglets/paramInfo/profil.dart](lib/is/onglets/paramInfo/profil.dart)

### Lignes Modifiées

1. **Ligne 35-38**: Définition des couleurs Mattermost
2. **Ligne 159**: SnackBar succès → `mattermostGreen`
3. **Ligne 187**: Scaffold background (loading) → `mattermostGray`
4. **Ligne 189**: AppBar background (loading) → `mattermostBlue`
5. **Ligne 191**: Titre AppBar → "Mon Profil Société"
6. **Ligne 201**: Scaffold background (null) → `mattermostGray`
7. **Ligne 203**: AppBar background (null) → `mattermostBlue`
8. **Ligne 205**: Titre AppBar → "Mon Profil Société"
9. **Ligne 213**: Scaffold background (main) → `mattermostGray`
10. **Ligne 215**: AppBar background (main) → `mattermostBlue`
11. **Ligne 258**: Avatar borderColor → `mattermostBlue`
12. **Ligne 297**: Chip section produits → `mattermostBlue`
13. **Ligne 508**: TextField focusedBorder → `mattermostBlue`

### Autres Couleurs Conservées

Certaines couleurs spécifiques restent différentes par design:
- **Services** (ligne 308): `Colors.blue` (bleu clair pour différencier)
- **Centres d'intérêt** (ligne 319): `Colors.orange` (orange pour variété)
- **Erreurs**: `Colors.red` (standard universel)
- **Déconnexion**: `Colors.red` (danger)

---

## 🎨 Palette de Couleurs Titingre

### Couleurs Principales

| Nom | Code Hex | RGB | Utilisation |
|-----|----------|-----|-------------|
| **Mattermost Blue** | `#1E4A8C` | `30, 74, 140` | AppBar, bordures actives, liens |
| **Mattermost Green** | `#28A745` | `40, 167, 69` | Messages succès, validations |
| **Mattermost Gray** | `#F4F4F4` | `244, 244, 244` | Background pages |

### Couleurs Secondaires

| Nom | Code | Utilisation |
|-----|------|-------------|
| **White** | `#FFFFFF` | Cartes, containers |
| **Gray 300** | `Colors.grey.shade300` | Bordures inactives |
| **Gray 600** | `Colors.grey.shade600` | Labels |
| **Black 87** | `Colors.black87` | Texte principal |
| **Red** | `Colors.red` | Erreurs, déconnexion |
| **Blue** | `Colors.blue` | Services (chips) |
| **Orange** | `Colors.orange` | Centres d'intérêt (chips) |

---

## 🔄 Historique des Modifications

| Date | Commit | Description |
|------|--------|-------------|
| 2026-01-09 | ca61dbc | Harmonisation couleurs profil IS avec IU |
| 2026-01-09 | 7ae07c9 | Ajout section informations lecture seule profil IS |
| 2026-01-09 | d7c61e9 | Fix profil société IS et HomePage IU dynamique |

---

## 📖 Références

- **Design System Mattermost**: [mattermost.com/design](https://mattermost.com/design)
- **Material Design Colors**: [material.io/design/color](https://material.io/design/color)
- **Flutter Color Class**: [api.flutter.dev/flutter/dart-ui/Color-class.html](https://api.flutter.dev/flutter/dart-ui/Color-class.html)

---

**Dernière mise à jour:** 2026-01-09
**Auteur:** Équipe Titingre
