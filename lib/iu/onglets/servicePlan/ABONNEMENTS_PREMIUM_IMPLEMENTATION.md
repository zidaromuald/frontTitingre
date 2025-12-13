# ⭐ Affichage des Abonnements Premium dans l'Onglet Sociétés

## 📍 Fichier modifié
**Emplacement**: `lib/iu/onglets/servicePlan/service.dart`

## 🎯 Vue d'ensemble

L'onglet "Société" dans la page Services affiche maintenant **deux types de relations avec les sociétés** :

1. **Sociétés suivies** (gratuit) - Relation de suivi simple
2. **Sociétés avec abonnement premium** (payant) - Abonnement accepté avec accès exclusif

Les sociétés premium sont visuellement distinguées avec :
- Badge "Premium" doré
- Icône étoile sur le logo
- Bordure orange autour de la carte

---

## ✅ Changements effectués

### 1️⃣ Ajout de l'import du service d'abonnement

```dart
import 'package:gestauth_clean/services/suivre/abonnement_auth_service.dart' as abonnement_service;
```

**Note**: Utilisation d'un préfixe `abonnement_service` pour éviter le conflit de nom avec `AbonnementModel` dans `suivre_auth_service.dart`.

### 2️⃣ Ajout des variables d'état pour les abonnements

```dart
List<abonnement_service.AbonnementModel> _mesAbonnements = [];
Set<int> _societeIdsAbonnees = {}; // IDs des sociétés avec abonnement premium
```

### 3️⃣ Modification de `_loadSuivieSocietes()` pour charger les abonnements

**Nouvelle logique** (lignes 129-182):

```dart
Future<void> _loadSuivieSocietes() async {
  setState(() => _isLoadingSocietes = true);

  try {
    // 1. Récupérer les abonnements actifs (premium)
    List<abonnement_service.AbonnementModel> abonnements = [];
    Set<int> societeIdsAbonnees = {};
    try {
      abonnements = await abonnement_service.AbonnementAuthService.getActiveSubscriptions();
      societeIdsAbonnees = abonnements.map((a) => a.societeId).toSet();
    } catch (e) {
      debugPrint('Erreur chargement abonnements: $e');
    }

    // 2. Récupérer les relations de suivi gratuit
    final suivis = await SuivreAuthService.getMyFollowing(
      type: EntityType.societe,
    );

    // 3. Combiner les IDs des sociétés (suivies + abonnées)
    Set<int> allSocieteIds = {...suivis.map((s) => s.followedId), ...societeIdsAbonnees};

    // 4. Charger les détails des sociétés
    List<SocieteModel> societes = [];
    for (var societeId in allSocieteIds) {
      try {
        final societe = await SocieteAuthService.getSocieteProfile(societeId);
        societes.add(societe);
      } catch (e) {
        debugPrint('Erreur chargement société $societeId: $e');
      }
    }

    if (mounted) {
      setState(() {
        _suivieSocietes = societes;
        _mesAbonnements = abonnements;
        _societeIdsAbonnees = societeIdsAbonnees;
        _isLoadingSocietes = false;
      });
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Flux détaillé**:
1. Charge les abonnements actifs via `AbonnementAuthService.getActiveSubscriptions()`
2. Extrait les IDs des sociétés abonnées dans un `Set`
3. Charge les suivis gratuits via `SuivreAuthService.getMyFollowing()`
4. Combine les IDs (union des deux listes pour éviter les doublons)
5. Charge les profils de toutes les sociétés
6. Met à jour l'état avec les données

### 4️⃣ Ajout du badge Premium dans le titre

**Lignes 558-599**:

```dart
Padding(
  padding: const EdgeInsets.all(16),
  child: Row(
    children: [
      Expanded(
        child: Text(
          "Sociétés (${_suivieSocietes.length})",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: mattermostDarkBlue,
          ),
        ),
      ),
      if (_mesAbonnements.isNotEmpty)
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
              Icon(Icons.star, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text(
                '${_mesAbonnements.length} Premium',
                style: TextStyle(
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
)
```

**Résultat**: Affiche un badge doré indiquant le nombre d'abonnements premium actifs.

### 5️⃣ Modification de `_buildSocieteItem()` pour afficher le statut Premium

**Lignes 617-696**:

```dart
Widget _buildSocieteItem(SocieteModel societe) {
  final bool isPremium = _societeIdsAbonnees.contains(societe.id);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: isPremium
        ? BoxDecoration(
            border: Border.all(
              color: const Color(0xffFFA500).withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          )
        : null,
    child: ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          // Logo de la société
          Container(...),

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
          Expanded(child: Text(societe.nom, ...)),

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
      subtitle: Text(societe.secteurActivite ?? 'Secteur non spécifié', ...),
      onTap: () => Navigator.push(...),
    ),
  );
}
```

**Éléments visuels pour les sociétés premium**:
1. **Bordure orange** autour de la carte
2. **Icône étoile orange** en badge sur le logo (en haut à droite)
3. **Badge "Premium" doré** à côté du nom de la société

---

## 📊 Design des cartes

### Société suivie (gratuit)
```
┌────────────────────────────────────────┐
│ 🏢  Société ABC                        │
│     Secteur d'activité                 │
└────────────────────────────────────────┘
```

### Société avec abonnement premium
```
┌────────────────────────────────────────┐ (bordure orange)
│ 🏢⭐ Société XYZ  [⭐ Premium]         │
│     Secteur d'activité                 │
└────────────────────────────────────────┘
```

**Couleurs**:
- Bordure: Orange (0xffFFA500 avec opacity 0.3)
- Badge étoile: Orange (0xffFFA500)
- Badge "Premium": Gradient or → orange (0xffFFD700 → 0xffFFA500)

---

## 🔄 Services utilisés

| Service | Méthode | Endpoint | Description |
|---------|---------|----------|-------------|
| `AbonnementAuthService` | `getActiveSubscriptions()` | `GET /abonnements/my-subscriptions?statut=actif` | Récupère mes abonnements actifs |
| `SuivreAuthService` | `getMyFollowing()` | `GET /suivis?type=societe` | Récupère les sociétés suivies |
| `SocieteAuthService` | `getSocieteProfile()` | `GET /societes/:id` | Charge le profil d'une société |

---

## 💡 Logique de combinaison

### Cas d'usage possibles

1. **User suit une société (gratuit uniquement)**
   - Apparaît dans la liste sans badge premium
   - Aucune bordure orange

2. **User est abonné à une société (premium accepté)**
   - Apparaît dans la liste AVEC badge premium
   - Bordure orange + étoile + badge "Premium"

3. **User suit ET est abonné à la même société**
   - La société n'apparaît qu'**une seule fois** dans la liste
   - Affichée AVEC le badge premium (priorité à l'abonnement)

### Algorithme de dédoublonnage

```dart
// Combiner les IDs (union)
Set<int> allSocieteIds = {
  ...suivis.map((s) => s.followedId),      // IDs suivis
  ...societeIdsAbonnees                     // IDs abonnés
};
```

Utilisation d'un `Set` pour éviter les doublons automatiquement.

---

## 🎨 Hiérarchie visuelle

1. **Titre de section** : "Sociétés (X)" + Badge compteur premium
2. **Liste de sociétés** :
   - Sociétés premium en premier (optionnel - actuellement ordre naturel)
   - Chaque société avec indication visuelle claire du statut

---

## 📦 Données du modèle `AbonnementModel`

```dart
class AbonnementModel {
  final int id;
  final int userId;
  final int societeId;              // ✅ Utilisé pour identifier la société
  final AbonnementStatut statut;    // actif, suspendu, expire, annule
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? planCollaboration;
  final List<String>? permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations optionnelles
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? societe;
}
```

**Champs utilisés**:
- `societeId` → Pour identifier quelle société est liée à l'abonnement
- `statut` → Filtre automatiquement les abonnements actifs via `getActiveSubscriptions()`

---

## ✅ Checklist de l'implémentation

- ✅ Import du service `AbonnementAuthService` avec préfixe
- ✅ Variables d'état pour abonnements et IDs
- ✅ Chargement des abonnements actifs au démarrage
- ✅ Combinaison des IDs suivis + abonnés (dédoublonnage)
- ✅ Badge compteur premium dans le titre
- ✅ Bordure orange pour les cartes premium
- ✅ Icône étoile sur le logo des sociétés premium
- ✅ Badge "Premium" doré à côté du nom
- ✅ Gestion des erreurs avec messages debug
- ✅ Refresh pour recharger abonnements + suivis

---

## 📅 Date de création
**2025-12-09**

## 📝 Statut
✅ **IMPLÉMENTÉ ET FONCTIONNEL**

---

## 🔗 Fichiers liés

- [service.dart](lib/iu/onglets/servicePlan/service.dart) - Page Services (onglet Société)
- [abonnement_auth_service.dart](lib/services/suivre/abonnement_auth_service.dart) - Service abonnements
- [suivre_auth_service.dart](lib/services/suivre/suivre_auth_service.dart) - Service suivis
- [SOCIETE_DEMANDES_ABONNEMENT_IMPLEMENTATION.md](lib/is/onglets/paramInfo/SOCIETE_DEMANDES_ABONNEMENT_IMPLEMENTATION.md) - Gestion côté société

---

## 🎯 Résumé

**Avant**:
- Affichage uniquement des sociétés suivies gratuitement
- Aucune distinction visuelle

**Après**:
- ✅ Affichage des sociétés suivies + abonnées (combinées)
- ✅ Badge compteur "X Premium" dans le titre
- ✅ Bordure orange pour les sociétés premium
- ✅ Icône étoile orange sur le logo
- ✅ Badge "Premium" doré à côté du nom
- ✅ Dédoublonnage automatique (pas de doublons si suivi + abonné)
- ✅ Chargement optimisé avec gestion d'erreur
