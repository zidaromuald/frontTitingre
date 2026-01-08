# 📋 Plan d'implémentation - Demandes d'abonnement et Posts Société

## 🎯 Objectifs

1. **Société** doit pouvoir gérer les demandes d'abonnement reçues
2. **User** doit pouvoir voir l'historique de ses demandes envoyées
3. **Société** doit pouvoir poster sur ses propres groupes créés

---

## 📊 État actuel des méthodes `DemandeAbonnementService`

### ✅ Méthodes DÉJÀ implémentées

| Méthode | Implémenté dans | Fichier | Statut |
|---------|----------------|---------|--------|
| `envoyerDemande()` | Profil société | `societe_profile_page.dart:236-262` | ✅ OK |
| `annulerDemande()` | Profil société | `societe_profile_page.dart:267-327` | ✅ OK |
| `checkDemandeExistante()` | Profil société | `societe_profile_page.dart:55-66` | ✅ OK |

### ❌ Méthodes NON implémentées

| Méthode | Réservé à | Utilisation | Priorité |
|---------|-----------|-------------|----------|
| `getMesDemandesEnvoyees()` | **User** | Voir historique demandes envoyées | 🟡 Moyenne |
| `accepterDemande()` | **Société** | Accepter demande d'abonnement | 🔴 **HAUTE** |
| `refuserDemande()` | **Société** | Refuser demande d'abonnement | 🔴 **HAUTE** |
| `getDemandesRecues()` | **Société** | Liste demandes reçues | 🔴 **HAUTE** |
| `countDemandesPending()` | **Société** | Badge notifications | 🔴 **HAUTE** |
| `getAllDemandesGrouped()` | **User** | Historique complet (optionnel) | 🟢 Basse |

---

## 🚀 Plan d'implémentation

### 1️⃣ **PRIORITÉ HAUTE** : Gestion des demandes côté Société

#### 📍 Fichier à créer : `lib/societe/demandes_abonnement_page.dart`

Une société doit pouvoir **voir et gérer** les demandes d'abonnement qu'elle reçoit.

**Fonctionnalités** :
- Afficher liste des demandes reçues (pending)
- Bouton "Accepter" → Crée automatiquement : Suivre + Abonnement + Page Partenariat
- Bouton "Refuser" → Marque la demande comme refusée
- Badge dans l'AppBar avec le nombre de demandes en attente

**Structure** :

```dart
import 'package:flutter/material.dart';
import '../services/suivre/demande_abonnement_service.dart';

class DemandesAbonnementPage extends StatefulWidget {
  const DemandesAbonnementPage({super.key});

  @override
  State<DemandesAbonnementPage> createState() => _DemandesAbonnementPageState();
}

class _DemandesAbonnementPageState extends State<DemandesAbonnementPage> {
  List<DemandeAbonnementModel> _demandesPending = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  /// Charger les demandes reçues (pending)
  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);

    try {
      final demandes = await DemandeAbonnementService.getDemandesRecues(
        status: DemandeAbonnementStatus.pending,
      );

      if (mounted) {
        setState(() {
          _demandesPending = demandes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Accepter une demande d'abonnement
  Future<void> _accepterDemande(DemandeAbonnementModel demande) async {
    try {
      final response = await DemandeAbonnementService.accepterDemande(demande.id);

      // Retirer de la liste locale
      setState(() {
        _demandesPending.remove(demande);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demande acceptée ! ${response.suivresCreated} relations créées.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Refuser une demande d'abonnement
  Future<void> _refuserDemande(DemandeAbonnementModel demande) async {
    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: Text(
          'Voulez-vous refuser la demande d\'abonnement de ${demande.user?['nom'] ?? 'cet utilisateur'} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DemandeAbonnementService.refuserDemande(demande.id);

      // Retirer de la liste locale
      setState(() {
        _demandesPending.remove(demande);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande refusée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'abonnement'),
        backgroundColor: const Color(0xff5ac18e),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _demandesPending.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune demande en attente'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _demandesPending.length,
                  itemBuilder: (context, index) {
                    final demande = _demandesPending[index];
                    return _buildDemandeCard(demande);
                  },
                ),
    );
  }

  Widget _buildDemandeCard(DemandeAbonnementModel demande) {
    final userName = demande.user != null
        ? '${demande.user!['nom'] ?? ''} ${demande.user!['prenom'] ?? ''}'.trim()
        : 'Utilisateur inconnu';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xff5ac18e),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Demande d\'abonnement',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (demande.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  demande.message!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _refuserDemande(demande),
                  child: const Text(
                    'Refuser',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _accepterDemande(demande),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff5ac18e),
                  ),
                  child: const Text(
                    'Accepter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**Intégration dans l'AppBar** (Badge notifications) :

```dart
// Dans HomePage ou AppBar principal
FutureBuilder<int>(
  future: DemandeAbonnementService.countDemandesPending(),
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DemandesAbonnementPage(),
          ),
        );
      },
      icon: Badge(
        label: count > 0 ? Text('$count') : null,
        isLabelVisible: count > 0,
        child: const Icon(Icons.notifications),
      ),
    );
  },
)
```

---

### 2️⃣ **PRIORITÉ MOYENNE** : Historique des demandes envoyées (côté User)

#### 📍 Fichier à modifier : `lib/iu/onglets/paramInfo/parametre.dart`

Ajouter une section "Mes demandes d'abonnement" après les invitations.

**Modifications** :

```dart
// Dans _ParametrePageState

// Ajouter variables d'état
List<DemandeAbonnementModel> _mesDemandesEnvoyees = [];
bool _isLoadingDemandes = false;

// Dans initState(), ajouter
_loadDemandesEnvoyees();

// Nouvelle méthode
Future<void> _loadDemandesEnvoyees() async {
  setState(() => _isLoadingDemandes = true);

  try {
    final demandes = await DemandeAbonnementService.getMesDemandesEnvoyees();

    if (mounted) {
      setState(() {
        _mesDemandesEnvoyees = demandes;
        _isLoadingDemandes = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingDemandes = false);
      // Gestion d'erreur
    }
  }
}

// Dans le build(), après la section "Invitations envoyées"
// Section Demandes d'abonnement envoyées
if (_isLoadingDemandes)
  const Center(child: CircularProgressIndicator())
else if (_mesDemandesEnvoyees.isNotEmpty) ...[
  Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.star,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Mes demandes d'abonnement (${_mesDemandesEnvoyees.length})",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: mattermostDarkBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._mesDemandesEnvoyees.map(
          (demande) => _buildDemandeAbonnementItem(demande),
        ),
      ],
    ),
  ),
  const SizedBox(height: 20),
],

// Nouveau widget
Widget _buildDemandeAbonnementItem(DemandeAbonnementModel demande) {
  final societeNom = demande.societe?['nom'] ?? 'Société inconnue';

  Color statusColor;
  IconData statusIcon;
  String statusText;

  switch (demande.status) {
    case DemandeAbonnementStatus.pending:
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
      statusText = 'En attente';
      break;
    case DemandeAbonnementStatus.accepted:
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Acceptée';
      break;
    case DemandeAbonnementStatus.declined:
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Refusée';
      break;
    case DemandeAbonnementStatus.cancelled:
      statusColor = Colors.grey;
      statusIcon = Icons.block;
      statusText = 'Annulée';
      break;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: mattermostGray,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: statusColor.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                societeNom,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(fontSize: 12, color: statusColor),
              ),
            ],
          ),
        ),
        if (demande.status == DemandeAbonnementStatus.accepted)
          const Icon(Icons.star, color: Colors.orange, size: 20),
      ],
    ),
  );
}
```

---

### 3️⃣ **PRIORITÉ HAUTE** : Société poste sur ses groupes

#### 📍 Fichier à modifier : `lib/iu/onglets/postInfo/post.dart`

Actuellement, `post.dart` charge **uniquement les groupes dont l'utilisateur est membre**.

**Problème** : Une société ne peut pas poster sur les groupes qu'elle a créés si elle n'est pas membre.

**Solution** : Détecter le type d'utilisateur (User vs Société) et charger les données appropriées.

**Modifications** :

```dart
// Dans _CreerPostPageState

// Ajouter variable
bool _isSociete = false;

// Modifier _loadMyGroupesAndSocietes()
Future<void> _loadMyGroupesAndSocietes() async {
  setState(() {
    _isLoadingGroupes = true;
    _isLoadingSocietes = true;
  });

  try {
    // Charger en parallèle
    final results = await Future.wait([
      GroupeAuthService.getMyGroupes(), // Mes groupes (créés ou rejoints)
      SuivreAuthService.getMyFollowing(type: EntityType.societe), // Sociétés que je suis
    ]);

    // Charger les détails des sociétés
    final suivisSocietes = results[1] as List<SuivreModel>;
    List<SocieteModel> societes = [];
    for (var suivi in suivisSocietes) {
      try {
        final societe = await SocieteAuthService.getSocieteProfile(suivi.followedId);
        societes.add(societe);
      } catch (e) {
        debugPrint('Erreur chargement société ${suivi.followedId}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _mesGroupes = results[0] as List<GroupeModel>;
        _mesSocietes = societes;
        _isLoadingGroupes = false;
        _isLoadingSocietes = false;
      });
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Note** : La méthode `GroupeAuthService.getMyGroupes()` retourne **TOUS** les groupes dont on est membre (créés ou rejoints). Si une société crée un groupe, elle est automatiquement admin/membre de ce groupe.

**Donc :** ✅ **PAS DE MODIFICATION NÉCESSAIRE** dans `post.dart` ! La logique actuelle fonctionne déjà.

**Explication** :
- Quand une société crée un groupe, elle devient automatiquement **admin** de ce groupe
- `GroupeAuthService.getMyGroupes()` retourne tous les groupes où on est membre (inclut les groupes créés)
- Donc une société voit déjà ses groupes créés dans la liste

---

## 📊 Résumé des actions

| Action | Fichier | Priorité | Statut |
|--------|---------|----------|--------|
| Créer page gestion demandes société | `lib/societe/demandes_abonnement_page.dart` | 🔴 HAUTE | ❌ À faire |
| Ajouter badge notifications | `HomePage` / `AppBar` | 🔴 HAUTE | ❌ À faire |
| Ajouter section demandes dans paramètres | `lib/iu/onglets/paramInfo/parametre.dart` | 🟡 MOYENNE | ❌ À faire |
| Société poste sur ses groupes | `lib/iu/onglets/postInfo/post.dart` | 🔴 HAUTE | ✅ **DÉJÀ FAIT** |

---

## ✅ Checklist finale

### Méthodes `DemandeAbonnementService`

- [x] `envoyerDemande()` - Implémenté dans `societe_profile_page.dart`
- [x] `annulerDemande()` - Implémenté dans `societe_profile_page.dart`
- [x] `checkDemandeExistante()` - Implémenté dans `societe_profile_page.dart`
- [ ] `getMesDemandesEnvoyees()` - **À implémenter dans `parametre.dart`**
- [ ] `accepterDemande()` - **À implémenter dans `demandes_abonnement_page.dart`**
- [ ] `refuserDemande()` - **À implémenter dans `demandes_abonnement_page.dart`**
- [ ] `getDemandesRecues()` - **À implémenter dans `demandes_abonnement_page.dart`**
- [ ] `countDemandesPending()` - **À implémenter dans badge AppBar**
- [ ] `getAllDemandesGrouped()` - Optionnel (historique complet)

### Fonctionnalités

- [x] User peut envoyer demande d'abonnement
- [x] User peut annuler sa demande
- [x] User voit état de sa demande (pending/declined)
- [ ] **Société peut voir demandes reçues**
- [ ] **Société peut accepter/refuser demandes**
- [ ] **Société a badge notifications**
- [ ] User voit historique de toutes ses demandes
- [x] **Société peut poster sur ses groupes créés** (déjà fonctionnel)

---

## 📅 Date de création
**2025-12-08**

## 📝 Prochaines étapes

1. **Créer `demandes_abonnement_page.dart`** pour les sociétés
2. **Ajouter badge notifications** dans l'AppBar
3. **Modifier `parametre.dart`** pour afficher historique des demandes

Voulez-vous que je commence par implémenter la page de gestion des demandes pour les sociétés ?
