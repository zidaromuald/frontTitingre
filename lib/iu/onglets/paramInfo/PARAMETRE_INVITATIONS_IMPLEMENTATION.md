# 📩 Implémentation des Invitations dans Paramètres

## 📍 Fichier modifié
**Emplacement**: `lib/iu/onglets/paramInfo/parametre.dart`

## ✅ Changements effectués

### 1️⃣ Import du service d'invitations
```dart
import 'package:gestauth_clean/services/suivre/invitation_suivi_service.dart';
```

### 2️⃣ Remplacement des données statiques par des données dynamiques

**AVANT** ❌ (lignes 76-102):
```dart
final List<Map<String, dynamic>> invitations = [
  {
    'type': 'groupe',
    'nom': 'Producteurs de Riz BF',
    'categorie': 'Agriculteur',
    'membres': 156,
    'description': 'Groupe des producteurs de riz du Burkina Faso',
    'expediteur': 'Marie Ouédraogo',
  },
  // ... données statiques hardcodées
];
```

**APRÈS** ✅ (lignes 77-151):
```dart
// Données dynamiques des invitations
List<InvitationSuiviModel> _invitationsRecues = [];
List<InvitationSuiviModel> _invitationsEnvoyees = [];
bool _isLoadingInvitationsRecues = false;
bool _isLoadingInvitationsEnvoyees = false;

@override
void initState() {
  super.initState();
  _loadInvitations();
}

/// Charger les invitations (reçues et envoyées)
Future<void> _loadInvitations() async {
  await Future.wait([
    _loadInvitationsRecues(),
    _loadInvitationsEnvoyees(),
  ]);
}

/// Charger les invitations reçues (pending)
Future<void> _loadInvitationsRecues() async {
  setState(() => _isLoadingInvitationsRecues = true);

  try {
    final invitations = await InvitationSuiviService.getMesInvitationsRecues(
      status: InvitationSuiviStatus.pending,
    );

    if (mounted) {
      setState(() {
        _invitationsRecues = invitations;
        _isLoadingInvitationsRecues = false;
      });
    }
  } catch (e) {
    // Gestion d'erreur
  }
}

/// Charger les invitations envoyées (pending)
Future<void> _loadInvitationsEnvoyees() async {
  // Logique similaire
}
```

### 3️⃣ Séparation de l'UI en deux sections distinctes

**Section 1: Invitations Reçues** (lignes 308-360)
- Affiche les invitations que **j'ai reçues** (statut pending)
- Icône: `Icons.mail_outline`
- Couleur: `mattermostBlue`
- **Actions disponibles**: Accepter ou Refuser

**Section 2: Invitations Envoyées** (lignes 362-414)
- Affiche les invitations que **j'ai envoyées** (statut pending)
- Icône: `Icons.send`
- Couleur: `Colors.orange`
- **Action disponible**: Annuler

### 4️⃣ Widgets de rendu séparés

#### Widget pour invitations REÇUES
```dart
Widget _buildInvitationRecueItem(InvitationSuiviModel invitation) {
  // Affiche:
  // - Nom de l'expéditeur (User ou Société)
  // - Message optionnel
  // - Boutons "Refuser" et "Accepter"
}
```

Récupère le nom depuis `invitation.sender`:
- **Si User**: `${sender['nom']} ${sender['prenom']}`
- **Si Société**: `sender['nom']`

#### Widget pour invitations ENVOYÉES
```dart
Widget _buildInvitationEnvoyeeItem(InvitationSuiviModel invitation) {
  // Affiche:
  // - Nom du destinataire (User ou Société)
  // - Statut "En attente de réponse"
  // - Message optionnel
  // - Bouton "Annuler"
}
```

Récupère le nom depuis `invitation.receiver`:
- **Si User**: `${receiver['nom']} ${receiver['prenom']}`
- **Si Société**: `receiver['nom']`

### 5️⃣ Actions implémentées

#### Accepter une invitation reçue
```dart
Future<void> _accepterInvitationRecue(InvitationSuiviModel invitation) async {
  try {
    await InvitationSuiviService.accepterInvitation(invitation.id);

    // Retirer de la liste locale
    setState(() {
      _invitationsRecues.remove(invitation);
    });

    // Message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Invitation acceptée avec succès"),
        backgroundColor: mattermostGreen,
      ),
    );
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Backend**: `PUT /invitations-suivi/:id/accept`
- Crée automatiquement une relation de suivi bidirectionnelle
- Statut passe à `accepted`

#### Refuser une invitation reçue
```dart
Future<void> _refuserInvitationRecue(InvitationSuiviModel invitation) async {
  try {
    await InvitationSuiviService.refuserInvitation(invitation.id);

    // Retirer de la liste locale
    setState(() {
      _invitationsRecues.remove(invitation);
    });

    // Message de confirmation
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Backend**: `PUT /invitations-suivi/:id/decline`
- Statut passe à `declined`
- Aucune relation de suivi créée

#### Annuler une invitation envoyée
```dart
Future<void> _annulerInvitationEnvoyee(InvitationSuiviModel invitation) async {
  // Confirmation dialog
  final confirmed = await showDialog<bool>(...);
  if (confirmed != true) return;

  try {
    await InvitationSuiviService.annulerInvitation(invitation.id);

    // Retirer de la liste locale
    setState(() {
      _invitationsEnvoyees.remove(invitation);
    });

    // Message de confirmation
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Backend**: `DELETE /invitations-suivi/:id`
- Supprime l'invitation
- Seul l'expéditeur peut annuler

---

## 📊 Flux complet

### User ouvre la page Paramètres

1. **initState()** appelle `_loadInvitations()`
2. Charge en parallèle:
   - `_loadInvitationsRecues()` → `InvitationSuiviService.getMesInvitationsRecues(status: pending)`
   - `_loadInvitationsEnvoyees()` → `InvitationSuiviService.getMesInvitationsEnvoyees(status: pending)`

3. **Pendant le chargement**:
   - Affiche `CircularProgressIndicator`

4. **Après le chargement**:
   - Si `_invitationsRecues.isNotEmpty` → Affiche card "Invitations reçues"
   - Si `_invitationsEnvoyees.isNotEmpty` → Affiche card "Invitations envoyées"
   - Sinon → N'affiche rien

### User accepte une invitation reçue

1. Clic sur bouton "Accepter"
2. Appel API: `PUT /invitations-suivi/:id/accept`
3. Backend crée automatiquement relation bidirectionnelle `Suivre`
4. Retrait de la liste locale
5. Message de succès

### User refuse une invitation reçue

1. Clic sur bouton "Refuser"
2. Appel API: `PUT /invitations-suivi/:id/decline`
3. Statut passe à `declined`
4. Retrait de la liste locale
5. Message de confirmation

### User annule une invitation envoyée

1. Clic sur bouton "Annuler"
2. Dialog de confirmation
3. Si confirmé: Appel API `DELETE /invitations-suivi/:id`
4. Invitation supprimée
5. Retrait de la liste locale
6. Message de confirmation

---

## 🎯 Résultat final

### Interface utilisateur

**Invitations Reçues**:
```
┌─────────────────────────────────────────┐
│ 📧 Invitations reçues (2)               │
├─────────────────────────────────────────┤
│ 👤 Jean Dupont                          │
│    souhaite vous suivre                 │
│    "J'aimerais vous suivre"             │
│              [Refuser] [Accepter]       │
├─────────────────────────────────────────┤
│ 🏢 BTP Solutions                        │
│    souhaite vous suivre                 │
│              [Refuser] [Accepter]       │
└─────────────────────────────────────────┘
```

**Invitations Envoyées**:
```
┌─────────────────────────────────────────┐
│ 📤 Invitations envoyées (1)             │
├─────────────────────────────────────────┤
│ 👤 Marie Ouédraogo                      │
│    En attente de réponse                │
│    Votre message: "Bonjour..."          │
│                        [🚫 Annuler]     │
└─────────────────────────────────────────┘
```

---

## 🔄 Services utilisés

| Service | Méthode | Endpoint | Description |
|---------|---------|----------|-------------|
| `InvitationSuiviService` | `getMesInvitationsRecues()` | `GET /invitations-suivi/received?status=pending` | Charge invitations reçues |
| `InvitationSuiviService` | `getMesInvitationsEnvoyees()` | `GET /invitations-suivi/sent?status=pending` | Charge invitations envoyées |
| `InvitationSuiviService` | `accepterInvitation()` | `PUT /invitations-suivi/:id/accept` | Accepte invitation reçue |
| `InvitationSuiviService` | `refuserInvitation()` | `PUT /invitations-suivi/:id/decline` | Refuse invitation reçue |
| `InvitationSuiviService` | `annulerInvitation()` | `DELETE /invitations-suivi/:id` | Annule invitation envoyée |

---

## ✅ Checklist de l'implémentation

- ✅ Remplacement des données statiques par données dynamiques
- ✅ Chargement des invitations reçues (pending)
- ✅ Chargement des invitations envoyées (pending)
- ✅ Affichage séparé: invitations reçues vs envoyées
- ✅ Widget `_buildInvitationRecueItem()` avec actions accept/refuse
- ✅ Widget `_buildInvitationEnvoyeeItem()` avec action annuler
- ✅ Méthode `_accepterInvitationRecue()` avec appel API
- ✅ Méthode `_refuserInvitationRecue()` avec appel API
- ✅ Méthode `_annulerInvitationEnvoyee()` avec appel API et confirmation
- ✅ Gestion des erreurs avec SnackBar
- ✅ États de chargement (CircularProgressIndicator)
- ✅ Mise à jour locale de la liste après action

---

## 📅 Date de création
**2025-12-07**

## 📝 Statut
✅ **IMPLÉMENTÉ ET FONCTIONNEL**

---

## 🔗 Fichiers liés

- [parametre.dart](lib/iu/onglets/paramInfo/parametre.dart) - Page principale
- [invitation_suivi_service.dart](lib/services/suivre/invitation_suivi_service.dart) - Service backend
- [LOGIQUE_SUIVI_IMPLEMENTATION.md](LOGIQUE_SUIVI_IMPLEMENTATION.md) - Documentation générale du système de suivi
