# Services Groupe

Ce dossier contient tous les services liés à la gestion des groupes dans l'application GestAuth.

## 📁 Structure des fichiers

```
groupe/
├── groupe_service.dart              # Service principal - Gestion des groupes
├── groupe_invitation_service.dart   # Gestion des invitations
├── groupe_membre_service.dart       # Gestion des membres
└── groupe_profil_service.dart       # Gestion des profils enrichis
```

## 📋 Services disponibles

### 1. **GroupeService** - Service Principal
**Fichier**: [groupe_service.dart](groupe_service.dart)

Service de base pour la gestion des groupes, incluant les modèles et enums partagés.

**Fonctionnalités principales** (9 endpoints GroupeController):
- ✅ Créer un groupe (User ou Société)
- ✅ Récupérer tous les groupes publics
- ✅ Rechercher des groupes (nom, tags, créateur)
- ✅ Récupérer mes groupes
- ✅ Récupérer un groupe par ID
- ✅ Mettre à jour un groupe
- ✅ Supprimer un groupe
- ✅ Archiver/désarchiver un groupe
- ✅ Quitter un groupe

**Modèles inclus**:
- `GroupeModel` - Modèle principal du groupe
- `GroupeProfilModel` - Profil enrichi (photo, logo, description, etc.)
- `GroupeUserModel` - Utilisateur membre d'un groupe
- `GroupeInvitationModel` - Invitation à rejoindre un groupe

**Enums**:
- `GroupeType` - Type de groupe (prive, public)
- `GroupeCategorie` - Catégorie selon le nombre de membres (simple, professionnel, supergroupe)
- `MembreRole` - Rôle dans le groupe (membre, moderateur, admin)
- `MembreStatus` - Statut du membre (active, suspended, banned)
- `InvitationStatus` - Statut de l'invitation (pending, accepted, declined, expired)

### 2. **GroupeInvitationService** - Invitations
**Fichier**: [groupe_invitation_service.dart](groupe_invitation_service.dart)

Service dédié à la gestion des invitations de groupe.

**Fonctionnalités** (4 endpoints GroupeInvitationController):
- ✅ Inviter un membre à rejoindre le groupe
- ✅ Consulter mes invitations reçues
- ✅ Accepter une invitation
- ✅ Refuser une invitation

**Méthodes utilitaires**:
- `filterPendingInvitations()` - Filtrer les invitations en attente
- `filterExpiredInvitations()` - Filtrer les invitations expirées
- `countPendingInvitations()` - Compter les invitations en attente

**Exemple d'utilisation**:
```dart
// Inviter un utilisateur
final invitation = await GroupeInvitationService.inviteMembre(
  groupeId: 1,
  invitedUserId: 42,
  message: 'Rejoins notre groupe!',
);

// Récupérer mes invitations
final invitations = await GroupeInvitationService.getMyInvitations();
final pending = GroupeInvitationService.filterPendingInvitations(invitations);

// Accepter une invitation
await GroupeInvitationService.acceptInvitation(invitation.id);
```

### 3. **GroupeMembreService** - Gestion des Membres
**Fichier**: [groupe_membre_service.dart](groupe_membre_service.dart)

Service dédié à la gestion des membres d'un groupe.

**Fonctionnalités** (7 endpoints GroupeMembreController):
- ✅ Récupérer la liste des membres
- ✅ Rejoindre un groupe public (sans invitation)
- ✅ Mettre à jour le rôle d'un membre
- ✅ Expulser un membre du groupe
- ✅ Suspendre un membre
- ✅ Bannir un membre définitivement

**Méthodes utilitaires**:
- `promoteToModerator()` - Promouvoir en modérateur
- `promoteToAdmin()` - Promouvoir en admin
- `demoteToMembre()` - Rétrograder en simple membre
- `countMembres()` - Compter le nombre de membres
- `filterByRole()` - Filtrer les membres par rôle
- `getAdmins()` - Récupérer uniquement les admins
- `getModerators()` - Récupérer uniquement les modérateurs
- `isUserMembre()` - Vérifier si un utilisateur est membre
- `isUserAdmin()` - Vérifier si un utilisateur est admin

**Exemple d'utilisation**:
```dart
// Rejoindre un groupe public
await GroupeMembreService.joinGroupe(groupeId: 5);

// Récupérer les membres
final membres = await GroupeMembreService.getMembres(groupeId: 5);

// Promouvoir un membre
await GroupeMembreService.promoteToModerator(groupeId: 5, userId: 42);

// Expulser un membre
await GroupeMembreService.removeMembre(groupeId: 5, userId: 99);

// Récupérer uniquement les admins
final admins = await GroupeMembreService.getAdmins(groupeId: 5);
```

### 4. **GroupeProfilService** - Profils Enrichis
**Fichier**: [groupe_profil_service.dart](groupe_profil_service.dart)

Service dédié à la gestion du profil enrichi d'un groupe.

**Fonctionnalités** (2 endpoints GroupeProfilController):
- ✅ Récupérer le profil enrichi d'un groupe
- ✅ Mettre à jour le profil (photo, logo, description, règles, tags, etc.)

**Champs du profil**:
- `photoCouverture` - Photo de couverture du groupe
- `logo` - Logo du groupe
- `description` - Description détaillée
- `regles` - Règles du groupe
- `tags` - Tags pour la recherche
- `localisation` - Localisation géographique
- `languePrincipale` - Langue principale du groupe
- `secteurActivite` - Secteur d'activité (pour les groupes professionnels)

**Méthodes de mise à jour partielle**:
- `updatePhotoCouverture()` - Mettre à jour uniquement la photo
- `updateLogo()` - Mettre à jour uniquement le logo
- `updateDescription()` - Mettre à jour uniquement la description
- `updateRegles()` - Mettre à jour uniquement les règles
- `updateTags()` - Mettre à jour les tags
- `addTag()` / `removeTag()` - Ajouter/retirer un tag
- `updateLocalisation()` - Mettre à jour la localisation
- `updateLanguePrincipale()` - Mettre à jour la langue
- `updateSecteurActivite()` - Mettre à jour le secteur

**Méthodes de validation**:
- `isProfilComplete()` - Vérifier si le profil est complet
- `calculateCompletenessScore()` - Calculer le score de complétude (0-100)
- `getMissingFields()` - Obtenir la liste des champs manquants

**Exemple d'utilisation**:
```dart
// Récupérer le profil
final profil = await GroupeProfilService.getProfil(groupeId: 5);

// Mettre à jour le profil complet
final updated = await GroupeProfilService.updateProfil(
  5,
  photoCouverture: 'https://example.com/cover.jpg',
  logo: 'https://example.com/logo.png',
  description: 'Un groupe pour les développeurs Flutter',
  tags: ['flutter', 'dart', 'mobile'],
  localisation: 'Paris, France',
  languePrincipale: 'fr',
);

// Mise à jour partielle
await GroupeProfilService.updateDescription(5, 'Nouvelle description');
await GroupeProfilService.addTag(5, 'developpement');

// Validation
final score = GroupeProfilService.calculateCompletenessScore(profil);
print('Profil complété à $score%');

final missing = GroupeProfilService.getMissingFields(profil);
if (missing.isNotEmpty) {
  print('Champs manquants: ${missing.join(', ')}');
}
```

## 🔄 Migration depuis l'ancien code

Les méthodes suivantes dans `GroupeService` sont **dépréciées** et redirigent vers les nouveaux services spécialisés:

### Membres (utilisez `GroupeMembreService`)
- ~~`GroupeService.joinGroupe()`~~ → `GroupeMembreService.joinGroupe()`
- ~~`GroupeService.getGroupeMembres()`~~ → `GroupeMembreService.getMembres()`
- ~~`GroupeService.removeMembre()`~~ → `GroupeMembreService.removeMembre()`
- ~~`GroupeService.updateMembreRole()`~~ → `GroupeMembreService.updateMembreRole()`
- ~~`GroupeService.suspendMembre()`~~ → `GroupeMembreService.suspendMembre()`
- ~~`GroupeService.banMembre()`~~ → `GroupeMembreService.banMembre()`

### Invitations (utilisez `GroupeInvitationService`)
- ~~`GroupeService.inviteMembre()`~~ → `GroupeInvitationService.inviteMembre()`
- ~~`GroupeService.getMyInvitations()`~~ → `GroupeInvitationService.getMyInvitations()`
- ~~`GroupeService.acceptInvitation()`~~ → `GroupeInvitationService.acceptInvitation()`
- ~~`GroupeService.declineInvitation()`~~ → `GroupeInvitationService.declineInvitation()`

### Profil (utilisez `GroupeProfilService`)
- ~~`GroupeService.getGroupeProfil()`~~ → `GroupeProfilService.getProfil()`
- ~~`GroupeService.updateGroupeProfil()`~~ → `GroupeProfilService.updateProfil()`

## 📊 Total des endpoints

**22 endpoints au total** répartis sur 4 controllers:
- **GroupeController**: 9 endpoints (service principal)
- **GroupeInvitationController**: 4 endpoints
- **GroupeMembreController**: 7 endpoints
- **GroupeProfilController**: 2 endpoints

## 🎯 Cas d'usage typiques

### 1. Créer et configurer un nouveau groupe

```dart
// 1. Créer le groupe
final groupe = await GroupeService.createGroupe(
  nom: 'Développeurs Flutter Paris',
  type: GroupeType.public,
);

// 2. Configurer le profil
await GroupeProfilService.updateProfil(
  groupe.id,
  photoCouverture: 'url_photo',
  logo: 'url_logo',
  description: 'Communauté de développeurs Flutter à Paris',
  tags: ['flutter', 'dart', 'paris', 'developpement'],
  localisation: 'Paris, France',
  languePrincipale: 'fr',
);

// 3. Inviter des membres
await GroupeInvitationService.inviteMembre(
  groupeId: groupe.id,
  invitedUserId: 42,
  message: 'Bienvenue dans notre groupe!',
);
```

### 2. Gérer les membres d'un groupe

```dart
// Récupérer tous les membres
final membres = await GroupeMembreService.getMembres(groupeId: 5);

// Filtrer par rôle
final admins = await GroupeMembreService.getAdmins(groupeId: 5);

// Promouvoir un membre actif
await GroupeMembreService.promoteToModerator(groupeId: 5, userId: 42);

// Modérer un membre problématique
await GroupeMembreService.suspendMembre(groupeId: 5, userId: 99);
```

### 3. Gérer mes invitations

```dart
// Récupérer mes invitations
final invitations = await GroupeInvitationService.getMyInvitations();

// Filtrer les invitations en attente
final pending = GroupeInvitationService.filterPendingInvitations(invitations);

// Accepter/Refuser
for (final inv in pending) {
  if (inv.groupe.nom.contains('Flutter')) {
    await GroupeInvitationService.acceptInvitation(inv.id);
  } else {
    await GroupeInvitationService.declineInvitation(inv.id);
  }
}
```

### 4. Rejoindre et explorer des groupes publics

```dart
// Rechercher des groupes
final results = await GroupeService.searchGroupes(
  search: 'flutter',
  type: GroupeType.public,
);

// Rejoindre un groupe public
await GroupeMembreService.joinGroupe(groupeId: results.first.id);

// Consulter le profil du groupe
final profil = await GroupeProfilService.getProfil(groupeId: results.first.id);
```

## 🔐 Authentification

Tous les services utilisent `ApiService` qui gère automatiquement:
- ✅ L'ajout du token JWT dans les headers
- ✅ La gestion des erreurs HTTP
- ✅ La sérialisation/désérialisation JSON

## 📚 Documentation complémentaire

- **Mapping des endpoints**: Voir [GROUPE_MAPPING.md](../documentation/GROUPE_MAPPING.md)
- **Documentation générale**: Voir [README principal](../documentation/README.md)
- **Architecture backend**: Consultez le dossier `backend/src/groupes/`

## ⚡ Bonnes pratiques

1. **Utilisez les services spécialisés** plutôt que les méthodes dépréciées dans `GroupeService`
2. **Gérez les erreurs** avec des try-catch pour toutes les opérations
3. **Vérifiez les permissions** avant d'effectuer des actions admin (promouvoir, bannir, etc.)
4. **Utilisez les méthodes utilitaires** pour les opérations courantes (filtrage, comptage, etc.)
5. **Validez les profils** avec `isProfilComplete()` et `calculateCompletenessScore()`

## 🐛 Gestion des erreurs

Toutes les méthodes peuvent lever des exceptions. Exemple de gestion:

```dart
try {
  await GroupeMembreService.banMembre(groupeId: 5, userId: 99);
  print('Membre banni avec succès');
} catch (e) {
  if (e.toString().contains('permission')) {
    print('Vous n\'avez pas la permission de bannir ce membre');
  } else {
    print('Erreur: $e');
  }
}
```

## 📝 Notes importantes

- Les groupes peuvent être créés par des **Users** ou des **Sociétés** (polymorphisme)
- Les groupes privés nécessitent une invitation pour rejoindre
- Les groupes publics peuvent être rejoints directement
- Seuls les admins peuvent modifier le profil, gérer les rôles et expulser des membres
- Les invitations expirent automatiquement après un certain délai
- Le score de complétude du profil influence la visibilité du groupe dans les recherches
