# Comparaison des Paramètres (Settings) - IS vs IU

## 📊 Vue d'ensemble

### Structure des Paramètres

```
lib/
├── is/onglets/paramInfo/           (Interface Société)
│   ├── parametre.dart              Page principale paramètres
│   ├── profil.dart                 Profil Société (éditable)
│   └── categorie.dart              Gestion catégories/canaux
│
└── iu/onglets/paramInfo/           (Interface User)
    ├── parametre.dart              Page principale paramètres
    ├── profil.dart                 Profil User (éditable)
    └── categorie.dart              Gestion catégories/canaux
```

---

## 🔍 Différences Logiques IS vs IU

### 1. Page Principale (parametre.dart)

| Aspect | IS (Société) | IU (User) | Logique |
|--------|--------------|-----------|---------|
| **Entité** | Société (entreprise) | User (individu) | Deux types d'acteurs différents |
| **Invitations reçues** | Demandes d'abonnement d'utilisateurs | Invitations de suivi de sociétés | Société reçoit des abonnements, User reçoit des invitations |
| **Invitations envoyées** | Invitations à des groupes | Invitations de suivi envoyées | Différents types d'invitations |
| **Profil** | SocieteModel | UserModel | Structures de données différentes |
| **Services** | `DemandeAbonnementService` + `GroupeInvitationService` | `InvitationSuiviService` | Services spécifiques à chaque type |

---

### 2. Page Profil (profil.dart)

| Champ | IS (Société) | IU (User) | Commentaire |
|-------|--------------|-----------|-------------|
| **Identité** | nom, secteurActivite, siret | nom, prenom, email, numero | Société vs Individu |
| **Description** | description (entreprise) | bio (personnelle) | Présentation différente |
| **Informations pro** | nombreEmployes, anneeCreation, chiffreAffaires | experience, formation | Données d'entreprise vs CV |
| **Activités** | produits, services | competences | Ce que fait l'entreprise vs Ce que sait faire la personne |
| **Contact** | siteWeb, email, telephone | numero, email | Contact pro vs Contact perso |
| **Certification** | certifications (ISO, etc.) | - | Spécifique aux sociétés |
| **Centres d'intérêt** | centresInteret | centresInteret | Commun aux deux |
| **Avatar** | logo | photo | Image de marque vs Photo personnelle |

---

### 3. Logique des Invitations

#### IS - Société reçoit des **Demandes d'Abonnement**

```dart
// IS charge les demandes d'abonnement reçues
final demandes = await DemandeAbonnementService.getDemandesRecues(
  status: DemandeAbonnementStatus.pending,
);
```

**Flux** :
```
User demande abonnement → Société
        ↓
Société reçoit la demande (pending)
        ↓
Société ACCEPTE ou REJETTE
        ↓
Si accepté → User devient abonné premium
            → Création page_partenariat
```

**Types de demandes reçues** :
- Demandes d'abonnement d'utilisateurs
- Invitations à rejoindre des groupes (autres sociétés/users)

#### IU - User reçoit des **Invitations de Suivi**

```dart
// IU charge les invitations de suivi reçues
final invitations = await InvitationSuiviService.getMesInvitationsRecues(
  status: InvitationSuiviStatus.pending,
);
```

**Flux** :
```
Société envoie invitation → User
        ↓
User reçoit l'invitation (pending)
        ↓
User ACCEPTE ou REJETTE
        ↓
Si accepté → User suit la société (follower gratuit)
```

**Types d'invitations reçues** :
- Invitations de suivi de sociétés
- Invitations à rejoindre des groupes
- Demandes de collaboration

---

## 📐 Problème de Taille des Containers

### ❌ Problème Actuel

Dans certains écrans IS, les containers ne s'adaptent pas correctement, causant :
- Overflow (débordement de pixels)
- Tailles fixes qui ne s'adaptent pas au contenu
- Différences de padding entre IS et IU

### ✅ Solution : Standardiser les Tailles

**Padding recommandé** :
```dart
// Padding principal des pages
const EdgeInsets.all(12.0)  // Au lieu de 16.0 pour éviter overflow

// Padding des containers
const EdgeInsets.symmetric(horizontal: 12, vertical: 8)

// Margin entre les éléments
const SizedBox(height: 12)  // Au lieu de 16
```

**Exemple de container corrigé** :
```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: // Contenu
)
```

---

## 🎨 Profil Société - Implémentation Manquante

### État Actuel

✅ **IS profil.dart** : IMPLÉMENTÉ
- Édition complète du profil société
- Champs spécifiques entreprise
- Sauvegarde via `SocieteAuthService.updateMyProfile()`

✅ **IU profil.dart** : IMPLÉMENTÉ
- Édition complète du profil utilisateur
- Champs spécifiques individu
- Sauvegarde via `UserAuthService.updateMyProfile()`

### ⚠️ Ce Qui Pourrait Manquer

**Navigation vers le profil** :

Vérifier que dans `parametre.dart` (IS), le bouton "Profil" navigue bien vers `ProfilDetailPage` :

```dart
// Dans parametre.dart IS
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilDetailPage(),
      ),
    );
  },
  child: // Card Profil
)
```

---

## 🔧 Corrections Recommandées

### 1. Standardiser les Containers (IS et IU)

**Fichiers à corriger** :
- `lib/is/onglets/paramInfo/parametre.dart`
- `lib/iu/onglets/paramInfo/parametre.dart`
- `lib/is/onglets/paramInfo/categorie.dart`
- `lib/iu/onglets/paramInfo/categorie.dart`

**Modifications** :
```dart
// ❌ AVANT
Container(
  padding: const EdgeInsets.all(16),  // Cause overflow
  // ...
)

// ✅ APRÈS
Container(
  padding: const EdgeInsets.all(12),  // Évite overflow
  // ...
)
```

### 2. Vérifier la Navigation vers le Profil (IS)

S'assurer que le profil société est accessible depuis les paramètres.

### 3. Uniformiser les Couleurs

Utiliser les mêmes couleurs Mattermost dans IS et IU :

```dart
static const Color mattermostBlue = Color(0xFF1E4A8C);
static const Color mattermostDarkBlue = Color(0xFF0B2340);
static const Color mattermostGray = Color(0xFFF4F4F4);
static const Color mattermostDarkGray = Color(0xFF8D8D8D);
static const Color mattermostGreen = Color(0xFF28A745);
```

---

## 📊 Tableau Récapitulatif des Différences

### Données Affichées

| Catégorie | IS (Société) | IU (User) |
|-----------|--------------|-----------|
| **Profil** | Logo, nom société, secteur | Photo, nom complet, bio |
| **Invitations** | Demandes abonnement (DemandeAbonnementService) | Invitations suivi (InvitationSuiviService) |
| **Groupes** | Invitations groupes (GroupeInvitationService) | Invitations groupes (similaire) |
| **Catégories** | Gestion canaux société | Gestion catégories user |
| **Statistiques** | Nombre abonnés, followers | Nombre abonnements, follows |

### Services Utilisés

| Fonctionnalité | IS (Société) | IU (User) |
|----------------|--------------|-----------|
| Profil | `SocieteAuthService.getMyProfile()` | `UserAuthService.getMyProfile()` |
| Mise à jour | `SocieteAuthService.updateMyProfile()` | `UserAuthService.updateMyProfile()` |
| Invitations | `DemandeAbonnementService.getDemandesRecues()` | `InvitationSuiviService.getMesInvitationsRecues()` |
| Invitations envoyées | `DemandeAbonnementService.getDemandesEnvoyees()` | `InvitationSuiviService.getMesInvitationsEnvoyees()` |
| Groupes | `GroupeInvitationService.getMyInvitations()` | (Pas directement utilisé) |
| Logout | `UnifiedAuthService.logout()` | `UnifiedAuthService.logout()` |

---

## 🎯 Logique Métier - Pourquoi Ces Différences ?

### 1. Nature de l'Entité

**Société (IS)** :
- Entité juridique (entreprise, organisation)
- Objectif : Trouver des clients, partenaires, employés
- Besoin : Gérer ses abonnés, proposer des services
- Données : Informations légales, commerciales, financières

**User (IU)** :
- Personne physique (individu)
- Objectif : Trouver du travail, des opportunités, des partenaires
- Besoin : Se faire connaître, développer son réseau
- Données : CV, compétences, expériences personnelles

### 2. Relations Asymétriques

```
┌─────────────────────────────────────────────────┐
│  SOCIÉTÉ                    USER                │
│                                                  │
│  Propose services   →    Recherche services     │
│  Recrute            →    Cherche emploi         │
│  Offre partenariat  →    Accepte partenariat    │
│  A des abonnés      ←    S'abonne à société     │
│  Reçoit followers   ←    Suit une société       │
└─────────────────────────────────────────────────┘
```

### 3. Workflow d'Abonnement

#### User → Société (Abonnement Premium)

```
1. User découvre Société
2. User clique "S'abonner" (premium payant)
3. User envoie DEMANDE D'ABONNEMENT
4. Société reçoit la demande (IS paramètres)
5. Société ACCEPTE ou REJETTE
6. Si accepté:
   - User devient abonné premium
   - Création page_partenariat
   - Accès aux services premium
   - Société peut créer transactions
```

#### User → Société (Suivi Gratuit)

```
1. User découvre Société
2. User clique "Suivre" (gratuit)
3. SUIVI IMMÉDIAT (pas d'approbation)
4. User devient follower
5. User voit les posts publics de la société
```

---

## 📝 Résumé

### Différences Principales

1. **Profil** :
   - IS : Profil société (entreprise)
   - IU : Profil utilisateur (individu)

2. **Invitations** :
   - IS : Demandes d'abonnement + Invitations groupes
   - IU : Invitations de suivi + Invitations groupes

3. **Services** :
   - IS : `DemandeAbonnementService`, `GroupeInvitationService`
   - IU : `InvitationSuiviService`

4. **Objectifs** :
   - IS : Gérer abonnés, proposer services, recruter
   - IU : Développer réseau, trouver opportunités, collaborer

### Points Communs

1. ✅ Structure de navigation identique
2. ✅ Design Mattermost cohérent
3. ✅ Gestion des catégories/canaux
4. ✅ Profil éditable
5. ✅ Notifications d'invitations
6. ✅ Déconnexion via `UnifiedAuthService`

### À Corriger

1. ⚠️ **Tailles des containers** : Standardiser padding à 12px au lieu de 16px
2. ⚠️ **Navigation profil IS** : Vérifier que le bouton fonctionne
3. ⚠️ **Overflow** : Réduire les marges dans les catégories

---

## 🚀 Plan d'Action

### Priorité 1 - Corrections Immédiates

- [ ] Réduire padding de 16px à 12px dans tous les containers IS
- [ ] Vérifier navigation vers ProfilDetailPage dans IS
- [ ] Corriger overflow dans categorie.dart IS

### Priorité 2 - Uniformisation

- [ ] Standardiser les couleurs dans IS et IU
- [ ] Uniformiser les espacements
- [ ] Harmoniser les animations

### Priorité 3 - Améliorations

- [ ] Ajouter statistiques dans les paramètres
- [ ] Améliorer feedback utilisateur
- [ ] Optimiser chargements
