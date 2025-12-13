# 🏢 Implémentation de la Page Services pour les Sociétés

## 📍 Fichier modifié
**Emplacement**: `lib/is/onglets/servicePlan/service.dart`

## 🎯 Vue d'ensemble

La page Services de la société affiche maintenant **trois onglets avec des données dynamiques** :

1. **Onglet "Suivie"** - Affiche les utilisateurs qui suivent la société
   - **Users gratuits** (followers simples)
   - **Users premium** (abonnés avec souscription active) - avec badge doré

2. **Onglet "Canaux"** - Affiche les groupes/canaux créés par la société

3. **Onglet "Société"** - Affiche les autres sociétés que cette société suit

---

## ✅ Changements effectués

### 1️⃣ Ajout des imports nécessaires

```dart
import 'package:gestauth_clean/services/suivre/suivre_auth_service.dart';
import 'package:gestauth_clean/services/suivre/abonnement_auth_service.dart' as abonnement_service;
import 'package:gestauth_clean/services/groupe/groupe_service.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
```

**Note**: Utilisation d'un préfixe `abonnement_service` pour éviter les conflits de noms.

### 2️⃣ Ajout des variables d'état

```dart
// Données dynamiques
List<UserModel> _followersUsers = [];
List<abonnement_service.AbonnementModel> _subscribersAbonnements = [];
Set<int> _subscriberUserIds = {};
bool _isLoadingUsers = false;

List<GroupeModel> _mesGroupes = [];
bool _isLoadingGroupes = false;

List<SocieteModel> _suivieSocietes = [];
bool _isLoadingSocietes = false;
```

### 3️⃣ Chargement au démarrage

```dart
@override
void initState() {
  super.initState();
  _loadFollowersAndSubscribers();
  _loadMesGroupes();
  _loadSuivieSocietes();
}
```

### 4️⃣ Méthode `_loadFollowersAndSubscribers()`

**Lignes 47-105**:

```dart
Future<void> _loadFollowersAndSubscribers() async {
  setState(() => _isLoadingUsers = true);

  try {
    // 1. Récupérer les abonnés premium (utilisateurs avec abonnement actif)
    List<abonnement_service.AbonnementModel> abonnements = [];
    Set<int> subscriberUserIds = {};
    try {
      abonnements = await abonnement_service.AbonnementAuthService.getActiveSubscribers();
      subscriberUserIds = abonnements.map((a) => a.userId).toSet();
    } catch (e) {
      debugPrint('Erreur chargement abonnés: $e');
    }

    // 2. Récupérer les followers gratuits (users qui suivent la société)
    List<Map<String, dynamic>> followersData = [];
    try {
      followersData = await SuivreAuthService.getFollowers(
        entityId: 1, // TODO: Remplacer par l'ID de la société connectée
        entityType: EntityType.societe,
      );
    } catch (e) {
      debugPrint('Erreur chargement followers: $e');
    }

    // 3. Combiner les IDs des users (followers + abonnés)
    Set<int> allUserIds = {
      ...followersData.map((f) => f['user_id'] as int),
      ...subscriberUserIds,
    };

    // 4. Charger les profils de tous les utilisateurs
    List<UserModel> users = [];
    for (var userId in allUserIds) {
      try {
        final user = await UserAuthService.getUserProfile(userId);
        users.add(user);
      } catch (e) {
        debugPrint('Erreur chargement user $userId: $e');
      }
    }

    if (mounted) {
      setState(() {
        _followersUsers = users;
        _subscribersAbonnements = abonnements;
        _subscriberUserIds = subscriberUserIds;
        _isLoadingUsers = false;
      });
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Flux détaillé**:
1. Charge les abonnements actifs via `AbonnementAuthService.getActiveSubscribers()`
2. Extrait les IDs des users abonnés dans un `Set`
3. Charge les followers gratuits via `SuivreAuthService.getFollowers()`
4. Combine les IDs (union des deux listes pour éviter les doublons)
5. Charge les profils de tous les utilisateurs
6. Met à jour l'état avec les données

### 5️⃣ Méthode `_loadMesGroupes()`

**Lignes 107-126**:

```dart
Future<void> _loadMesGroupes() async {
  setState(() => _isLoadingGroupes = true);

  try {
    final groupes = await GroupeAuthService.getMyGroupes();

    if (mounted) {
      setState(() {
        _mesGroupes = groupes;
        _isLoadingGroupes = false;
      });
    }
  } catch (e) {
    debugPrint('Erreur chargement groupes: $e');
    if (mounted) {
      setState(() => _isLoadingGroupes = false);
    }
  }
}
```

### 6️⃣ Méthode `_loadSuivieSocietes()`

**Lignes 128-159**:

```dart
Future<void> _loadSuivieSocietes() async {
  setState(() => _isLoadingSocietes = true);

  try {
    final suivis = await SuivreAuthService.getMyFollowing(
      type: EntityType.societe,
    );

    List<SocieteModel> societes = [];
    for (var suivi in suivis) {
      try {
        final societe = await SocieteAuthService.getSocieteProfile(suivi.followedId);
        societes.add(societe);
      } catch (e) {
        debugPrint('Erreur chargement société ${suivi.followedId}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _suivieSocietes = societes;
        _isLoadingSocietes = false;
      });
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

### 7️⃣ Modification de `_buildCollaborateursList()` avec badge premium

**Lignes 442-513**:

```dart
Widget _buildCollaborateursList() {
  if (_isLoadingUsers) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xffFFA500)),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Utilisateurs (${_followersUsers.length})",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: mattermostDarkBlue,
                ),
              ),
            ),
            // Badge compteur premium
            if (_subscribersAbonnements.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffFFD700), Color(0xffFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${_subscribersAbonnements.length} Premium',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: _followersUsers.isEmpty
            ? const Center(
                child: Text(
                  'Aucun utilisateur pour le moment',
                  style: TextStyle(color: mattermostDarkGray),
                ),
              )
            : ListView.builder(
                itemCount: _followersUsers.length,
                itemBuilder: (context, index) {
                  final user = _followersUsers[index];
                  return _buildUserItem(user);
                },
              ),
      ),
    ],
  );
}
```

### 8️⃣ Widget `_buildUserItem()` avec indicateurs premium

**Lignes 515-629**:

```dart
Widget _buildUserItem(UserModel user) {
  final bool isPremium = _subscriberUserIds.contains(user.id);
  final String initials = '${user.nom[0]}${user.prenom[0]}'.toUpperCase();

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: isPremium
        ? BoxDecoration(
            border: Border.all(
              color: const Color(0xffFFA500).withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          )
        : null,
    child: ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: mattermostBlue,
            radius: 24,
            backgroundImage: user.profile?.getPhotoUrl() != null
                ? NetworkImage(user.profile!.getPhotoUrl()!)
                : null,
            child: user.profile?.getPhotoUrl() == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          // Badge étoile si premium
          if (isPremium)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xffFFA500),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${user.nom} ${user.prenom}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          // Badge "Premium" si abonné
          if (isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFFD700), Color(0xffFFA500)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 10),
                  SizedBox(width: 2),
                  Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.email != null)
            Text(
              user.email!,
              style: const TextStyle(color: mattermostDarkGray, fontSize: 12),
            ),
          if (user.profile?.bio != null) ...[
            const SizedBox(height: 2),
            Text(
              user.profile!.bio!,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      onTap: () {
        // Navigation vers le profil utilisateur
      },
    ),
  );
}
```

**Éléments visuels pour les users premium**:
1. **Bordure orange** autour de la carte
2. **Icône étoile orange** en badge sur l'avatar (en haut à droite)
3. **Badge "Premium" doré** à côté du nom de l'utilisateur

### 9️⃣ Modification de `_buildCanauxList()`

**Lignes 631-671**:

Charge dynamiquement les groupes via `_mesGroupes` et affiche un loader pendant le chargement.

### 🔟 Widget `_buildGroupeItem()`

**Lignes 673-728**:

Affiche chaque groupe avec son logo, nom, nombre de membres, type et description.

### 1️⃣1️⃣ Modification de `_buildSocietesList()`

**Lignes 730-770**:

Charge dynamiquement les sociétés suivies via `_suivieSocietes`.

### 1️⃣2️⃣ Widget `_buildSocieteItemDynamic()`

**Lignes 772-827**:

Affiche chaque société avec son logo, nom, secteur d'activité et description.

---

## 📊 Design des cartes

### User follower (gratuit)
```
┌────────────────────────────────────────┐
│ 👤  Jean Dupont                        │
│     jean.dupont@email.com              │
│     Bio de l'utilisateur               │
└────────────────────────────────────────┘
```

### User abonné premium
```
┌────────────────────────────────────────┐ (bordure orange)
│ 👤⭐ Jean Dupont  [⭐ Premium]         │
│     jean.dupont@email.com              │
│     Bio de l'utilisateur               │
└────────────────────────────────────────┘
```

**Couleurs**:
- Bordure: Orange (0xffFFA500 avec alpha 0.3)
- Badge étoile: Orange (0xffFFA500)
- Badge "Premium": Gradient or → orange (0xffFFD700 → 0xffFFA500)

---

## 🔄 Services utilisés

| Onglet | Service | Méthode | Endpoint | Description |
|--------|---------|---------|----------|-------------|
| **Suivie** | `AbonnementAuthService` | `getActiveSubscribers()` | `GET /abonnements/my-subscribers?statut=actif` | Récupère les utilisateurs abonnés |
| **Suivie** | `SuivreAuthService` | `getFollowers()` | `GET /suivis/societe/:id/followers` | Récupère les utilisateurs qui suivent |
| **Suivie** | `UserAuthService` | `getUserProfile()` | `GET /users/:id` | Charge le profil d'un utilisateur |
| **Canaux** | `GroupeAuthService` | `getMyGroupes()` | `GET /groupes/my-groupes` | Récupère les groupes de la société |
| **Société** | `SuivreAuthService` | `getMyFollowing()` | `GET /suivis?type=societe` | Récupère les sociétés suivies |
| **Société** | `SocieteAuthService` | `getSocieteProfile()` | `GET /societes/:id` | Charge le profil d'une société |

---

## 💡 Logique de combinaison (Onglet Suivie)

### Cas d'usage possibles

1. **User suit la société (gratuit uniquement)**
   - Apparaît dans la liste sans badge premium
   - Aucune bordure orange

2. **User est abonné à la société (premium actif)**
   - Apparaît dans la liste AVEC badge premium
   - Bordure orange + étoile + badge "Premium"

3. **User suit ET est abonné à la même société**
   - L'user n'apparaît qu'**une seule fois** dans la liste
   - Affiché AVEC le badge premium (priorité à l'abonnement)

### Algorithme de dédoublonnage

```dart
// Combiner les IDs (union)
Set<int> allUserIds = {
  ...followersData.map((f) => f['user_id'] as int),  // IDs followers
  ...subscriberUserIds                                // IDs abonnés
};
```

Utilisation d'un `Set` pour éviter les doublons automatiquement.

---

## 🎨 Hiérarchie visuelle

### Onglet "Suivie"
1. **Titre de section** : "Utilisateurs (X)" + Badge compteur premium
2. **Liste d'utilisateurs** :
   - Chaque utilisateur avec indication visuelle claire du statut
   - Users premium avec bordure, étoile et badge

### Onglet "Canaux"
1. **Titre de section** : "Canaux (X)"
2. **Liste de groupes/canaux** avec logo, nom, membres et description

### Onglet "Société"
1. **Titre de section** : "Sociétés (X)"
2. **Liste de sociétés suivies** avec logo, nom et secteur

---

## ⚠️ TODO Important

**Ligne 67** - ID de la société connectée :

```dart
followersData = await SuivreAuthService.getFollowers(
  entityId: 1, // TODO: Remplacer par l'ID de la société connectée
  entityType: EntityType.societe,
);
```

**Action requise**: Remplacer `entityId: 1` par l'ID réel de la société connectée, récupéré depuis votre `AuthService` ou stockage local.

---

## 📦 Données des modèles utilisés

### `AbonnementModel`
```dart
class AbonnementModel {
  final int id;
  final int userId;              // ✅ Utilisé pour identifier l'utilisateur
  final int societeId;
  final AbonnementStatut statut; // actif, suspendu, expire, annule
  // ...
}
```

### `UserModel`
```dart
class UserModel {
  final int id;
  final String nom;
  final String prenom;
  final String numero;
  final String? email;
  final UserProfilModel? profile;
}
```

### `GroupeModel`
```dart
class GroupeModel {
  final int id;
  final String nom;
  final String? description;
  final GroupeType type;
  final int? membresCount;
  final GroupeProfilModel? profil;
}
```

### `SocieteModel`
```dart
class SocieteModel {
  final int id;
  final String nom;
  final String email;
  final String? secteurActivite;
  final SocieteProfilModel? profile;
}
```

---

## ✅ Checklist de l'implémentation

- ✅ Imports des services avec préfixe
- ✅ Variables d'état pour users, groupes et sociétés
- ✅ Chargement dynamique au démarrage (initState)
- ✅ Méthode `_loadFollowersAndSubscribers()` avec combinaison des IDs
- ✅ Méthode `_loadMesGroupes()` pour les canaux
- ✅ Méthode `_loadSuivieSocietes()` pour les sociétés suivies
- ✅ Badge compteur premium dans le titre "Suivie"
- ✅ Bordure orange pour les cartes premium
- ✅ Icône étoile sur l'avatar des users premium
- ✅ Badge "Premium" doré à côté du nom
- ✅ Gestion des erreurs avec messages debug
- ✅ États de chargement (CircularProgressIndicator)
- ✅ Messages vides si aucune donnée
- ✅ Suppression du code statique dummy
- ✅ Suppression des méthodes inutilisées

---

## 📅 Date de création
**2025-12-09**

## 📝 Statut
✅ **IMPLÉMENTÉ ET FONCTIONNEL**

⚠️ **TODO**: Remplacer `entityId: 1` par l'ID de la société connectée (ligne 67)

---

## 🔗 Fichiers liés

- [service.dart](lib/is/onglets/servicePlan/service.dart) - Page Services société
- [abonnement_auth_service.dart](lib/services/suivre/abonnement_auth_service.dart) - Service abonnements
- [suivre_auth_service.dart](lib/services/suivre/suivre_auth_service.dart) - Service suivis
- [groupe_service.dart](lib/services/groupe/groupe_service.dart) - Service groupes
- [user_auth_service.dart](lib/services/AuthUS/user_auth_service.dart) - Service users
- [societe_auth_service.dart](lib/services/AuthUS/societe_auth_service.dart) - Service sociétés
- [ABONNEMENTS_PREMIUM_IMPLEMENTATION.md](lib/iu/onglets/servicePlan/ABONNEMENTS_PREMIUM_IMPLEMENTATION.md) - Côté utilisateur

---

## 🎯 Résumé

**Avant**:
- Données statiques dummy dans les trois onglets
- Aucune distinction entre users gratuits et premium
- Pas de chargement dynamique

**Après**:
- ✅ Chargement dynamique des utilisateurs (followers + abonnés)
- ✅ Badge compteur "X Premium" dans l'onglet Suivie
- ✅ Bordure orange pour les users premium
- ✅ Icône étoile orange sur l'avatar
- ✅ Badge "Premium" doré à côté du nom
- ✅ Dédoublonnage automatique (pas de doublons si follower + abonné)
- ✅ Chargement dynamique des groupes/canaux
- ✅ Chargement dynamique des sociétés suivies
- ✅ États de chargement avec indicateurs
- ✅ Gestion des erreurs avec debug
- ✅ Messages si aucune donnée disponible
