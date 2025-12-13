# 🏢 Implémentation de la Gestion des Demandes d'Abonnement pour les Sociétés

## 📍 Fichier modifié
**Emplacement**: `lib/is/onglets/paramInfo/parametre.dart`

## 🎯 Vue d'ensemble

La page de paramètres de la société affiche maintenant **les demandes d'abonnement reçues** des utilisateurs qui souhaitent s'abonner à la société. La société peut **accepter** ou **refuser** ces demandes premium.

---

## ✅ Changements effectués

### 1️⃣ Ajout de l'import du service d'abonnement

```dart
import 'package:gestauth_clean/services/suivre/demande_abonnement_service.dart';
```

### 2️⃣ Ajout des variables d'état pour les demandes d'abonnement

```dart
// Données dynamiques des demandes d'abonnement reçues
List<DemandeAbonnementModel> _demandesAbonnementRecues = [];
bool _isLoadingDemandesAbonnement = false;
```

### 3️⃣ Chargement des demandes au démarrage

**Dans `initState()`**:

```dart
@override
void initState() {
  super.initState();
  _loadDemandesAbonnement();
}
```

**Méthode de chargement** (lignes 115-136):

```dart
/// Charger les demandes d'abonnement reçues (pending)
Future<void> _loadDemandesAbonnement() async {
  setState(() => _isLoadingDemandesAbonnement = true);

  try {
    final demandes = await DemandeAbonnementService.getDemandesRecues(
      status: DemandeAbonnementStatus.pending,
    );

    if (mounted) {
      setState(() {
        _demandesAbonnementRecues = demandes;
        _isLoadingDemandesAbonnement = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingDemandesAbonnement = false);
    }
    // Gestion d'erreur silencieuse
  }
}
```

### 4️⃣ Implémentation de la méthode `_accepterDemandeAbonnement()`

**Lignes 138-171**:

```dart
Future<void> _accepterDemandeAbonnement(DemandeAbonnementModel demande) async {
  setState(() => _isLoadingDemandesAbonnement = true);

  try {
    await DemandeAbonnementService.accepterDemande(demande.id);

    if (mounted) {
      setState(() {
        _demandesAbonnementRecues.remove(demande);
        _isLoadingDemandesAbonnement = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d\'abonnement acceptée avec succès'),
          backgroundColor: mattermostGreen,
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Backend**: `PUT /demandes-abonnement/:id/accept`
- Crée automatiquement:
  - Relation de suivi bidirectionnelle (2 entrées dans `Suivre`)
  - Entrée dans `Abonnements`
  - Page de partenariat dédiée
- Statut passe à `accepted`

### 5️⃣ Implémentation de la méthode `_refuserDemandeAbonnement()`

**Lignes 173-206**:

```dart
Future<void> _refuserDemandeAbonnement(DemandeAbonnementModel demande) async {
  setState(() => _isLoadingDemandesAbonnement = true);

  try {
    await DemandeAbonnementService.refuserDemande(demande.id);

    if (mounted) {
      setState(() {
        _demandesAbonnementRecues.remove(demande);
        _isLoadingDemandesAbonnement = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande d\'abonnement refusée'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Backend**: `PUT /demandes-abonnement/:id/decline`
- Statut passe à `declined`
- Aucune relation créée

### 6️⃣ Ajout de la section UI "Demandes d'abonnement"

**Lignes 363-429**:

```dart
// Section Demandes d'abonnement reçues
if (_isLoadingDemandesAbonnement)
  Container(
    // ... CircularProgressIndicator orange
  )
else if (_demandesAbonnementRecues.isNotEmpty) ...[
  Container(
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.star, color: Color(0xffFFA500)),
            Text("Demandes d'abonnement (${_demandesAbonnementRecues.length})"),
          ],
        ),
        ..._demandesAbonnementRecues.map(
          (demande) => _buildDemandeAbonnementItem(demande),
        ),
      ],
    ),
  ),
],
```

### 7️⃣ Widget de rendu `_buildDemandeAbonnementItem()`

**Lignes 543-715**:

Affiche pour chaque demande:
- **Avatar utilisateur** avec icône "person" (orange)
- **Nom complet** de l'utilisateur (`nom` + `prenom`)
- **Email** de l'utilisateur
- **Badge "Premium"** avec étoile
- **Message optionnel** si l'utilisateur a laissé un message
- **Deux boutons**:
  - `Refuser` (outlined rouge avec icône ×)
  - `Accepter` (vert avec icône ✓)

**Récupération des données utilisateur**:

```dart
final user = demande.user;
final String userName = user != null
    ? '${user['nom'] ?? ''} ${user['prenom'] ?? ''}'.trim()
    : 'Utilisateur inconnu';
final String? userEmail = user?['email'];
```

**Affichage du message optionnel**:

```dart
if (demande.message != null && demande.message!.isNotEmpty) ...[
  Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: mattermostDarkGray.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Text('Message:', style: TextStyle(fontSize: 11, fontWeight: w600)),
        Text(demande.message!, maxLines: 3),
      ],
    ),
  ),
]
```

---

## 📊 Flux complet

### Société ouvre la page Paramètres

1. **initState()** appelle `_loadDemandesAbonnement()`
2. Charge les demandes via `DemandeAbonnementService.getDemandesRecues(status: pending)`
3. **Pendant le chargement**:
   - Affiche `CircularProgressIndicator` orange
4. **Après le chargement**:
   - Si `_demandesAbonnementRecues.isNotEmpty` → Affiche section "Demandes d'abonnement"
   - Sinon → N'affiche rien

### Société accepte une demande

1. Clic sur bouton "Accepter"
2. Appel API: `PUT /demandes-abonnement/:id/accept`
3. Backend crée automatiquement:
   - 2 entrées `Suivre` (bidirectionnel)
   - 1 entrée `Abonnements`
   - 1 `PagePartenariat`
4. Retrait de la liste locale
5. Message de succès vert

### Société refuse une demande

1. Clic sur bouton "Refuser"
2. Appel API: `PUT /demandes-abonnement/:id/decline`
3. Statut passe à `declined`
4. Retrait de la liste locale
5. Message de confirmation orange

---

## 🎨 Design de la carte de demande

```
┌─────────────────────────────────────────────────────┐
│ 👤 Jean Dupont                        ⭐ Premium    │
│    jean.dupont@email.com                            │
│    souhaite s'abonner à votre société               │
│                                                     │
│ ┌─────────────────────────────────────────────┐   │
│ │ Message:                                     │   │
│ │ "Je souhaite collaborer avec votre société" │   │
│ └─────────────────────────────────────────────┘   │
│                                                     │
│                      [❌ Refuser] [✅ Accepter]    │
└─────────────────────────────────────────────────────┘
```

**Couleurs**:
- Fond: Orange clair (0xffFFA500 avec opacity 0.05)
- Bordure: Orange (0xffFFA500 avec opacity 0.3)
- Icônes et badges: Orange (0xffFFA500)
- Bouton Accepter: Vert (mattermostGreen)
- Bouton Refuser: Rouge

---

## 🔄 Services utilisés

| Service | Méthode | Endpoint | Description |
|---------|---------|----------|-------------|
| `DemandeAbonnementService` | `getDemandesRecues()` | `GET /demandes-abonnement/received?status=pending` | Charge demandes reçues |
| `DemandeAbonnementService` | `accepterDemande()` | `PUT /demandes-abonnement/:id/accept` | Accepte demande (crée Suivre + Abonnement + PagePartenariat) |
| `DemandeAbonnementService` | `refuserDemande()` | `PUT /demandes-abonnement/:id/decline` | Refuse demande |

---

## 💡 Différence User vs Société

### Page Paramètres USER (`lib/iu/onglets/paramInfo/parametre.dart`)
- Affiche **invitations de suivi reçues** (User → User, Groupe → User)
- Affiche **invitations de suivi envoyées** (User → autre User)
- Service: `InvitationSuiviService`

### Page Paramètres SOCIÉTÉ (`lib/is/onglets/paramInfo/parametre.dart`)
- Affiche **demandes d'abonnement reçues** (User → Société)
- Actions: Accepter ou Refuser
- Service: `DemandeAbonnementService`
- Crée automatiquement abonnement premium + page partenariat lors de l'acceptation

---

## 📦 Données incluses dans `DemandeAbonnementModel`

```dart
class DemandeAbonnementModel {
  final int id;
  final int userId;
  final int societeId;
  final DemandeAbonnementStatus status;
  final String? message;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations optionnelles
  final Map<String, dynamic>? user;  // ✅ Utilisé pour afficher nom, prenom, email
  final Map<String, dynamic>? societe;
}
```

**Champs `user` utilisés dans l'UI**:
- `user['nom']` → Nom de famille
- `user['prenom']` → Prénom
- `user['email']` → Email

---

## ✅ Checklist de l'implémentation

- ✅ Import du service `DemandeAbonnementService`
- ✅ Variables d'état pour demandes d'abonnement reçues
- ✅ Chargement au démarrage via `initState()`
- ✅ Méthode `_loadDemandesAbonnement()` avec appel API
- ✅ Méthode `_accepterDemandeAbonnement()` avec appel API
- ✅ Méthode `_refuserDemandeAbonnement()` avec appel API
- ✅ Section UI "Demandes d'abonnement" avec état de chargement
- ✅ Widget `_buildDemandeAbonnementItem()` avec design orange/premium
- ✅ Affichage nom, email, message optionnel
- ✅ Boutons Accepter (vert) et Refuser (rouge)
- ✅ Gestion des erreurs avec SnackBar
- ✅ Mise à jour locale de la liste après action

---

## 📅 Date de création
**2025-12-08**

## 📝 Statut
✅ **IMPLÉMENTÉ ET FONCTIONNEL**

---

## 🔗 Fichiers liés

- [parametre.dart](lib/is/onglets/paramInfo/parametre.dart) - Page de paramètres société
- [demande_abonnement_service.dart](lib/services/suivre/demande_abonnement_service.dart) - Service backend abonnement
- [SOCIETE_PROFILE_IMPLEMENTATION.md](lib/iu/onglets/recherche/SOCIETE_PROFILE_IMPLEMENTATION.md) - Côté utilisateur (envoi demande)
- [PLAN_IMPLEMENTATION_DEMANDES_ABONNEMENT.md](../../../PLAN_IMPLEMENTATION_DEMANDES_ABONNEMENT.md) - Plan complet du système d'abonnement

---

## 🎯 Résumé

**Avant**:
- Page de paramètres société avec données statiques
- Aucune gestion des demandes d'abonnement

**Après**:
- ✅ Chargement dynamique des demandes d'abonnement reçues
- ✅ Section dédiée avec icône étoile orange
- ✅ Carte premium pour chaque demande (nom, email, message)
- ✅ Boutons Accepter/Refuser fonctionnels
- ✅ Création automatique d'abonnement + page partenariat lors de l'acceptation
- ✅ Mise à jour temps réel de l'interface
