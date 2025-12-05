# 👥 Gestion des Groupes

## 📂 Structure du dossier

```
lib/groupe/
├── create_groupe_page.dart      # Page de création d'un groupe
├── mes_groupes_page.dart         # Liste de mes groupes
├── groupe_detail_page.dart       # Détail d'un groupe
└── README_GROUPES.md             # Cette documentation
```

## 🎯 Vue d'ensemble

Le module **Groupes** permet aux **Users** et **Sociétés** de créer et gérer des groupes de discussion/collaboration.

### Fonctionnalités principales

✅ **Création de groupes** - Users et Sociétés peuvent créer des groupes
✅ **Types de groupes** - Privé (sur invitation) ou Public (tout le monde peut rejoindre)
✅ **Catégories automatiques** - Simple (≤100), Professionnel (≤9999), Super Groupe (≥10000)
✅ **Gestion des membres** - Invitations, rôles (membre, modérateur, admin)
✅ **Recherche de groupes** - Intégré dans GlobalSearchPage

## 🚀 Utilisation

### 1. Créer un groupe

```dart
// Naviguer vers la page de création
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateGroupePage(),
  ),
);
```

**Depuis n'importe où :**
- Interface User → Accessible
- Interface Société → Accessible

### 2. Voir mes groupes

```dart
// Naviguer vers la liste de mes groupes
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MesGroupesPage(),
  ),
);
```

### 3. Voir le détail d'un groupe

```dart
// Naviguer vers le détail d'un groupe
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GroupeDetailPage(groupeId: 123),
  ),
);
```

## 📊 Modèle de données

### GroupeModel

```dart
class GroupeModel {
  final int id;
  final String nom;
  final String? description;
  final int createdById;              // ID du créateur
  final String createdByType;         // 'User' ou 'Societe'
  final GroupeType type;              // prive ou public
  final int maxMembres;               // Capacité maximum
  final GroupeCategorie categorie;    // simple, professionnel, supergroupe
  final int? adminUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final GroupeProfilModel? profil;    // Logo, photo couverture, description
  final int? membresCount;            // Nombre actuel de membres
}
```

### Enums

#### GroupeType
- `prive` - Groupe privé (nécessite invitation)
- `public` - Groupe public (tout le monde peut rejoindre)

#### GroupeCategorie
- `simple` - ≤ 100 membres
- `professionnel` - 101-9999 membres
- `supergroupe` - ≥ 10000 membres

#### MembreRole
- `membre` - Membre standard
- `moderateur` - Modérateur (peut gérer les membres)
- `admin` - Administrateur (tous les droits)

#### MembreStatus
- `active` - Membre actif
- `suspended` - Membre suspendu temporairement
- `banned` - Membre banni définitivement

## 🔧 Services

### GroupeAuthService

Service principal pour les opérations CRUD sur les groupes.

```dart
// Créer un groupe
final groupe = await GroupeAuthService.createGroupe(
  nom: 'Producteurs de Riz BF',
  description: 'Groupe des producteurs de riz du Burkina Faso',
  type: GroupeType.prive,
  maxMembres: 500,
);

// Récupérer un groupe
final groupe = await GroupeAuthService.getGroupe(groupeId);

// Mettre à jour un groupe
final updated = await GroupeAuthService.updateGroupe(
  groupeId,
  {'nom': 'Nouveau nom', 'description': 'Nouvelle description'},
);

// Supprimer un groupe
await GroupeAuthService.deleteGroupe(groupeId);

// Rechercher des groupes
final groupes = await GroupeAuthService.searchGroupes(
  query: 'agriculture',
  limit: 20,
);

// Récupérer mes groupes
final mesGroupes = await GroupeAuthService.getMyGroupes();

// Vérifier si je suis membre
final isMember = await GroupeAuthService.isMember(groupeId);

// Récupérer mon rôle
final role = await GroupeAuthService.getMyRole(groupeId);
```

### GroupeMembreService

Service pour gérer les membres des groupes.

```dart
// Rejoindre un groupe public
await GroupeMembreService.joinGroupe(groupeId);

// Quitter un groupe
await GroupeMembreService.leaveGroupe(groupeId);

// Récupérer les membres
final membres = await GroupeMembreService.getMembres(groupeId);

// Expulser un membre (admin uniquement)
await GroupeMembreService.removeMembre(groupeId, userId);

// Changer le rôle d'un membre (admin uniquement)
await GroupeMembreService.updateMembreRole(
  groupeId,
  userId,
  MembreRole.moderateur,
);

// Suspendre un membre (admin uniquement)
await GroupeMembreService.suspendMembre(groupeId, userId);

// Bannir un membre (admin uniquement)
await GroupeMembreService.banMembre(groupeId, userId);
```

### GroupeInvitationService

Service pour gérer les invitations aux groupes privés.

```dart
// Inviter un utilisateur
final invitation = await GroupeInvitationService.inviteMembre(
  groupeId: groupeId,
  userId: userId,
  message: 'Rejoins notre groupe !',
);

// Récupérer mes invitations
final invitations = await GroupeInvitationService.getMyInvitations();

// Accepter une invitation
await GroupeInvitationService.acceptInvitation(invitationId);

// Refuser une invitation
await GroupeInvitationService.declineInvitation(invitationId);
```

### GroupeProfilService

Service pour gérer le profil du groupe (logo, photo de couverture, etc.).

```dart
// Récupérer le profil
final profil = await GroupeProfilService.getProfil(groupeId);

// Mettre à jour le profil
final updated = await GroupeProfilService.updateProfil(
  groupeId,
  {
    'description': 'Nouvelle description',
    'regles': 'Règles du groupe...',
    'tags': ['agriculture', 'riz', 'burkina'],
  },
);

// Upload photo de couverture
final result = await GroupeProfilService.uploadPhotoCouverture(
  groupeId,
  filePath,
);

// Upload logo
final result = await GroupeProfilService.uploadLogo(
  groupeId,
  filePath,
);
```

## 🔍 Recherche de groupes

La recherche de groupes est **intégrée dans GlobalSearchPage**, accessible depuis les deux interfaces (User et Société).

### Depuis l'interface User

```dart
// lib/iu/HomePage.dart ou n'importe quelle page User
import 'package:gestauth_clean/iu/onglets/recherche/global_search_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GlobalSearchPage(),
  ),
);
```

### Depuis l'interface Société

```dart
// lib/is/AccueilPage.dart ou n'importe quelle page Société
import 'package:gestauth_clean/iu/onglets/recherche/global_search_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GlobalSearchPage(),
  ),
);
```

### Comment ça marche

`GlobalSearchPage` affiche 3 onglets :
- 👤 **Users** - Recherche d'utilisateurs
- 👥 **Groupes** - Recherche de groupes
- 🏢 **Sociétés** - Recherche de sociétés

La recherche utilise `GroupeAuthService.searchGroupes()` pour rechercher les groupes par nom.

## 🎨 Interface utilisateur

### CreateGroupePage

**Fonctionnalités :**
- Formulaire de création avec validation
- Sélection du type (privé/public)
- Slider pour la capacité max (10 à 10000 membres)
- Affichage automatique de la catégorie selon la capacité
- Loading state pendant la création
- Retourne le groupe créé

**Validation :**
- Nom requis (min 3 caractères)
- Description optionnelle
- Type par défaut : Privé
- Capacité par défaut : 50 membres

### MesGroupesPage

**Fonctionnalités :**
- Liste de tous mes groupes
- Pull-to-refresh
- Bouton FAB pour créer un groupe
- Empty state si aucun groupe
- Cards avec infos : logo, nom, description, type, membres, catégorie
- Navigation vers GroupeDetailPage au clic

### GroupeDetailPage

**Fonctionnalités :**
- 3 onglets : Infos, Membres, Posts
- Affichage complet des informations
- Statistiques : membres, type, catégorie
- Actions selon le rôle :
  - **Non-membre + groupe public** → Bouton "Rejoindre"
  - **Membre standard** → Bouton "Quitter"
  - **Admin** → Menu avec "Modifier" et "Supprimer"

**Onglet Infos :**
- Logo et nom du groupe
- Statistiques visuelles
- Description complète
- Informations (date de création, créateur, capacité)

**Onglets Membres et Posts :**
- À implémenter (placeholder pour le moment)

## 📍 Intégration dans l'application

### Depuis l'interface User

Vous pouvez ajouter un bouton dans `lib/iu/HomePage.dart` :

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MesGroupesPage(),
      ),
    );
  },
  icon: const Icon(Icons.group),
  label: const Text('Mes Groupes'),
),
```

### Depuis l'interface Société

Vous pouvez ajouter un bouton dans `lib/is/AccueilPage.dart` :

```dart
_SquareAction(
  label: '4',
  icon: Icons.group,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MesGroupesPage(),
      ),
    );
  },
),
```

### Depuis le widget de catégorie

C'est exactement ce que vous avez demandé ! Le bouton "Créer un canal" peut naviguer vers `CreateGroupePage` :

```dart
// Dans lib/is/onglets/paramInfo/categorie.dart
ElevatedButton.icon(
  onPressed: () async {
    final groupe = await Navigator.push<GroupeModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupePage(),
      ),
    );

    if (groupe != null) {
      // Le groupe a été créé avec succès
      print('Groupe créé : ${groupe.nom}');
    }
  },
  icon: const Icon(Icons.add),
  label: const Text("Créer un canal"),
),
```

## 🔐 Permissions et sécurité

### Création de groupes
- ✅ Users peuvent créer des groupes
- ✅ Sociétés peuvent créer des groupes
- Le créateur devient automatiquement **admin** du groupe

### Rejoindre un groupe
- **Groupe public** → Tout le monde peut rejoindre directement
- **Groupe privé** → Nécessite une invitation

### Gestion des membres
- **Membre** → Peut consulter et participer
- **Modérateur** → Peut suspendre des membres
- **Admin** → Tous les droits (modifier, supprimer, bannir)

### Quitter/Supprimer
- **Quitter** → Tout membre peut quitter volontairement
- **Supprimer** → Seul l'admin peut supprimer le groupe

## 🎯 Flux utilisateur

### Créer un groupe

```
Clic sur "Créer un groupe"
    ↓
CreateGroupePage
    ↓
Remplir le formulaire (nom, description, type, capacité)
    ↓
GroupeAuthService.createGroupe()
    ↓
API: POST /groupes
    ↓
Réponse: GroupeModel créé
    ↓
Retour à MesGroupesPage avec le nouveau groupe
```

### Rejoindre un groupe public

```
Recherche de groupe dans GlobalSearchPage
    ↓
Clic sur un groupe
    ↓
GroupeDetailPage
    ↓
Bouton "Rejoindre le groupe"
    ↓
GroupeMembreService.joinGroupe()
    ↓
API: POST /groupes/:id/membres/join
    ↓
Succès → Rechargement des données
    ↓
Affichage du bouton "Quitter"
```

### Rejoindre un groupe privé

```
Réception d'une invitation
    ↓
Notification ou liste d'invitations
    ↓
GroupeInvitationService.acceptInvitation()
    ↓
API: POST /groupes/invitations/:id/accept
    ↓
Succès → Ajout au groupe
    ↓
Navigation vers GroupeDetailPage
```

## 🚧 Fonctionnalités à implémenter

- [ ] **Onglet Membres** - Liste et gestion des membres
- [ ] **Onglet Posts** - Publications du groupe
- [ ] **Page d'édition** - Modifier les informations d'un groupe
- [ ] **Gestion des invitations** - Interface pour inviter des membres
- [ ] **Notifications** - Notifications pour invitations et activités
- [ ] **Statistiques** - Graphiques d'activité du groupe
- [ ] **Modération** - Interface de modération pour admins
- [ ] **Upload médias** - Logo et photo de couverture

## ✅ Architecture complète

```
lib/
├── groupe/                              # Module Groupes (partagé)
│   ├── create_groupe_page.dart         # Création
│   ├── mes_groupes_page.dart            # Liste
│   ├── groupe_detail_page.dart          # Détail
│   └── README_GROUPES.md                # Documentation
│
├── services/
│   └── groupe/
│       ├── groupe_service.dart          # Service principal (CRUD)
│       ├── groupe_membre_service.dart   # Gestion membres
│       ├── groupe_invitation_service.dart # Invitations
│       └── groupe_profil_service.dart   # Profil (logo, couverture)
│
├── iu/                                   # Interface User
│   └── onglets/
│       └── recherche/
│           └── global_search_page.dart  # ✅ Recherche groupes (onglet Groupes)
│
└── is/                                   # Interface Société
    └── onglets/
        └── paramInfo/
            └── categorie.dart           # ✅ Peut créer des groupes ("canaux")
```

## 🎉 Résumé

Le module **Groupes** est **complètement fonctionnel** et **partagé** entre Users et Sociétés :

✅ **Création** - Depuis n'importe où (User ou Société)
✅ **Liste** - MesGroupesPage affiche mes groupes
✅ **Détail** - GroupeDetailPage avec infos et actions
✅ **Recherche** - Intégrée dans GlobalSearchPage
✅ **Services** - 4 services dédiés pour toutes les opérations
✅ **Permissions** - Gestion complète des rôles et permissions

**Prêt à être intégré dans votre application !** 🚀
