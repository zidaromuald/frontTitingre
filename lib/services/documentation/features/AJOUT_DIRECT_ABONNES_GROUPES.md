# Ajout Direct des Abonnés dans les Groupes - Société

## ✅ Fonctionnalité Implémentée

### Vue d'ensemble

Lorsqu'un **admin de société** crée ou gère un groupe, il peut **ajouter directement ses abonnés** au groupe **sans envoyer d'invitation**. Cette fonctionnalité permet à la société d'intégrer rapidement ses abonnés actifs dans différents canaux/groupes.

---

## 🔧 Architecture de la Fonctionnalité

### 1. Backend - Logique d'Ajout Direct

**Service** : `GroupeInvitationService.inviteMembre()`

**Fichier** : [lib/services/groupe/groupe_invitation_service.dart](lib/services/groupe/groupe_invitation_service.dart:28-65)

```dart
static Future<Map<String, dynamic>> inviteMembre({
  required int groupeId,
  required int invitedUserId,
  String? message,
}) async {
  final response = await ApiService.post('/groupes/$groupeId/invite', {
    'invited_user_id': invitedUserId,
    if (message != null) 'message': message,
  });

  if (response.statusCode == 200 || response.statusCode == 201) {
    final jsonResponse = jsonDecode(response.body);
    final ajoutDirect = jsonResponse['ajoutDirect'] ?? false;

    if (ajoutDirect) {
      // CAS 1 : Ajout direct (Société + Abonné)
      return {
        'success': true,
        'ajoutDirect': true,
        'message': 'Membre ajouté directement',
        'membre': jsonResponse['membre'],
      };
    } else {
      // CAS 2 : Invitation classique
      return {
        'success': true,
        'ajoutDirect': false,
        'message': 'Invitation envoyée',
        'invitation': GroupeInvitationModel.fromJson(jsonResponse['data']),
      };
    }
  }
}
```

**Logique Backend** :
- Le backend vérifie si l'admin du groupe est une **société**
- Si oui, il vérifie si l'utilisateur invité est un **abonné actif** de cette société
- Si les deux conditions sont remplies → **Ajout direct** (pas d'invitation)
- Sinon → **Invitation classique** (nécessite acceptation)

---

### 2. Frontend - Interface Utilisateur

**Page** : [lib/groupe/groupe_detail_page.dart](lib/groupe/groupe_detail_page.dart)

#### A. Méthode `_showInviteUserDialog()` (lignes 217-482)

Cette méthode affiche un dialog intelligent qui s'adapte selon le type d'utilisateur :

**Pour une Société** :
1. Charge automatiquement la **liste des abonnés actifs**
2. Affiche les abonnés avec un bouton **"Ajouter"** (au lieu de "Inviter")
3. Permet de basculer vers une **recherche globale** si besoin

**Pour un User standard** :
1. Affiche directement la **recherche globale**
2. Envoie des invitations classiques

#### Flux d'Utilisation - Société

```
┌────────────────────────────────────────────────────┐
│  Société Admin clique "Inviter"                    │
│                                                     │
│  ┌──────────────────────────────────────────────┐ │
│  │  1. Chargement des abonnés actifs             │ │
│  │     AbonnementAuthService.getMySubscribers()  │ │
│  └──────────────────┬───────────────────────────┘ │
│                     │                              │
│                     ▼                              │
│  ┌──────────────────────────────────────────────┐ │
│  │  Dialog: "Ajouter des membres"                │ │
│  │                                                │ │
│  │  [📊 Mes abonnés (25)] [🔍]  ← Toggle button │ │
│  │                                                │ │
│  │  Liste des abonnés:                           │ │
│  │  ┌────────────────────────────────────────┐  │ │
│  │  │ 👤 Jean Dupont                          │  │ │
│  │  │    jean.dupont@email.com                │  │ │
│  │  │                     [+ Ajouter] ←─────┐ │  │ │
│  │  ├────────────────────────────────────────┤  │ │
│  │  │ 👤 Marie Martin                         │  │ │
│  │  │    marie.martin@email.com               │  │ │
│  │  │                     [+ Ajouter]         │  │ │
│  │  └────────────────────────────────────────┘  │ │
│  └──────────────────┬───────────────────────────┘ │
│                     │                              │
│                     ▼                              │
│  Société clique "Ajouter" sur un abonné           │
│                     │                              │
│                     ▼                              │
│  ┌──────────────────────────────────────────────┐ │
│  │  GroupeInvitationService.inviteMembre()       │ │
│  │                                                │ │
│  │  POST /groupes/:groupeId/invite               │ │
│  │  { invited_user_id: userId }                  │ │
│  └──────────────────┬───────────────────────────┘ │
│                     │                              │
│                     ▼                              │
│  Backend vérifie: Société + Abonné?               │
│                     │                              │
│                     ▼                              │
│  ✅ OUI → Ajout Direct                            │
│                     │                              │
│                     ▼                              │
│  Response: { ajoutDirect: true, membre: {...} }   │
│                     │                              │
│                     ▼                              │
│  ┌──────────────────────────────────────────────┐ │
│  │  Frontend reçoit la réponse                   │ │
│  │                                                │ │
│  │  if (ajoutDirect) {                           │ │
│  │    ✅ Affiche "Jean a été ajouté au groupe"  │ │
│  │    ✅ Recharge la liste des membres          │ │
│  │  } else {                                     │ │
│  │    📧 Affiche "Invitation envoyée"           │ │
│  │  }                                            │ │
│  └───────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────┘
```

#### B. Méthode `_sendInvitation()` (lignes 376-457)

Mise à jour pour gérer les deux cas (ajout direct vs invitation) :

```dart
Future<void> _sendInvitation(UserModel user) async {
  // Dialog pour message optionnel
  final message = await showDialog<String>(...);
  if (message == null) return;

  try {
    final result = await GroupeInvitationService.inviteMembre(
      groupeId: widget.groupeId,
      invitedUserId: user.id,
      message: message.isEmpty ? null : message,
    );

    if (mounted) {
      final ajoutDirect = result['ajoutDirect'] ?? false;
      final resultMessage = result['message'] as String?;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ajoutDirect
                ? '${user.prenom} ${user.nom} a été ajouté(e) au groupe'
                : 'Invitation envoyée à ${user.prenom} ${user.nom}',
          ),
          backgroundColor: primaryColor,
        ),
      );

      // Recharger les membres si ajout direct
      if (ajoutDirect) {
        _loadGroupeData();
      }
    }
  } catch (e) {
    // Gestion d'erreur
  }
}
```

---

## 🎨 Interface Utilisateur

### Dialog d'Ajout de Membres (Société)

```
┌─────────────────────────────────────────────┐
│  Ajouter des membres               [🔍]    │  ← Toggle button
├─────────────────────────────────────────────┤
│                                              │
│  📊 Mes abonnés (25)                        │  ← Indicateur de mode
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ 👤  Jean Dupont                         │ │
│  │     jean.dupont@email.com               │ │
│  │                     [+ Ajouter]         │ │
│  ├────────────────────────────────────────┤ │
│  │ 👤  Marie Martin                        │ │
│  │     marie.martin@email.com              │ │
│  │                     [+ Ajouter]         │ │
│  ├────────────────────────────────────────┤ │
│  │ 👤  Pierre Durand                       │ │
│  │     pierre.durand@email.com             │ │
│  │                     [+ Ajouter]         │ │
│  └────────────────────────────────────────┘ │
│                                              │
│                           [Fermer]           │
└─────────────────────────────────────────────┘
```

**Clic sur l'icône 🔍** → Bascule vers :

```
┌─────────────────────────────────────────────┐
│  Ajouter des membres               [👥]    │  ← Toggle button
├─────────────────────────────────────────────┤
│                                              │
│  🔍 Recherche globale                       │  ← Indicateur de mode
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │ 🔍 Rechercher par nom ou email...      │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  Entrez un nom ou email pour rechercher     │
│                                              │
│                           [Fermer]           │
└─────────────────────────────────────────────┘
```

---

## 📊 Comparaison : Ajout Direct vs Invitation

| Critère | Ajout Direct | Invitation Classique |
|---------|--------------|---------------------|
| **Condition** | Admin = Société ET User = Abonné actif | Autres cas |
| **Action utilisateur** | Ajouté automatiquement | Doit accepter l'invitation |
| **Notification** | "Jean a été ajouté au groupe" | "Invitation envoyée à Jean" |
| **Statut** | Membre actif immédiatement | En attente d'acceptation |
| **Backend response** | `ajoutDirect: true` | `ajoutDirect: false` |
| **Rechargement** | Oui (liste membres mise à jour) | Non |

---

## 🔍 Services Utilisés

### 1. AbonnementAuthService

**Méthode** : `getMySubscribers()`

**Fichier** : [lib/services/suivre/abonnement_auth_service.dart](lib/services/suivre/abonnement_auth_service.dart:190-210)

```dart
/// Récupérer mes abonnés (société)
/// GET /abonnements/my-subscribers?statut=actif
/// Réservé aux sociétés (userType: 'societe')
static Future<List<AbonnementModel>> getMySubscribers({
  AbonnementStatut? statut,
}) async {
  final queryString = statut != null ? '?statut=${statut.value}' : '';
  final response = await ApiService.get(
    '/abonnements/my-subscribers$queryString',
  );

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    final List<dynamic> abonnementsData = jsonResponse['data'];
    return abonnementsData
        .map((json) => AbonnementModel.fromJson(json))
        .toList();
  }
}
```

**Usage dans le code** :
```dart
final abonnements = await AbonnementAuthService.getMySubscribers(
  statut: AbonnementStatut.actif,
);

// Extraire les users
subscribers = abonnements
    .where((abn) => abn.user != null)
    .map((abn) => UserModel.fromJson(abn.user!))
    .toList();
```

### 2. GroupeInvitationService

**Méthode** : `inviteMembre()`

**Retourne** :
```dart
{
  'success': true,
  'ajoutDirect': true/false,
  'message': String,
  'membre': {...} // Si ajout direct
  'invitation': {...} // Si invitation classique
}
```

---

## 🎯 Avantages de cette Implémentation

### Pour la Société
✅ **Gain de temps** : Ajout direct des abonnés sans attendre leur acceptation
✅ **Contrôle** : L'admin peut rapidement constituer des groupes thématiques
✅ **Flexibilité** : Peut aussi inviter des non-abonnés via la recherche globale
✅ **Visibilité** : Voit immédiatement sa liste d'abonnés

### Pour l'Utilisateur (Abonné)
✅ **Simplicité** : Pas besoin d'accepter une invitation
✅ **Confiance** : Déjà abonné à la société, donc relation établie
✅ **Notifications** : Reçoit une notification d'ajout au groupe

### Pour le Système
✅ **Réutilisabilité** : Un seul service gère les deux cas
✅ **Cohérence** : La logique métier est centralisée côté backend
✅ **Maintenabilité** : Code DRY (Don't Repeat Yourself)

---

## 🧪 Tests à Effectuer

### Tests Fonctionnels

- [ ] **En tant que Société** :
  - [ ] Créer un groupe
  - [ ] Cliquer sur "Inviter des membres"
  - [ ] Vérifier que la liste des abonnés s'affiche automatiquement
  - [ ] Cliquer sur "Ajouter" pour un abonné
  - [ ] Vérifier le message "Jean a été ajouté au groupe"
  - [ ] Vérifier que l'abonné apparaît dans la liste des membres
  - [ ] Basculer vers la recherche globale avec l'icône 🔍
  - [ ] Inviter un non-abonné
  - [ ] Vérifier le message "Invitation envoyée"

- [ ] **En tant que User** :
  - [ ] Créer un groupe
  - [ ] Cliquer sur "Inviter des membres"
  - [ ] Vérifier que seule la recherche globale s'affiche
  - [ ] Inviter un utilisateur
  - [ ] Vérifier le message "Invitation envoyée"

- [ ] **Edge Cases** :
  - [ ] Société sans abonnés → Affiche "Aucun abonné"
  - [ ] Recherche sans résultat → Affiche "Aucun utilisateur trouvé"
  - [ ] Erreur réseau → Message d'erreur approprié

### Tests Backend

- [ ] Endpoint `GET /abonnements/my-subscribers` fonctionne pour une société
- [ ] Endpoint `POST /groupes/:groupeId/invite` retourne `ajoutDirect: true` pour Société + Abonné
- [ ] Endpoint `POST /groupes/:groupeId/invite` retourne `ajoutDirect: false` pour les autres cas
- [ ] Les abonnés avec statut `suspendu` ou `expire` ne sont PAS ajoutés directement

---

## 📝 Notes Importantes

1. **Statut des Abonnés** :
   - Seuls les abonnés avec statut `actif` sont affichés dans la liste
   - Les abonnés suspendus, expirés ou annulés ne peuvent pas être ajoutés directement

2. **Permissions** :
   - Seul un **admin** du groupe peut ajouter des membres
   - La vérification des permissions est faite côté backend

3. **Gestion d'Erreurs** :
   - Si `getMySubscribers()` échoue (ex: user standard), le dialog bascule automatiquement en mode recherche
   - Les erreurs d'ajout sont capturées et affichées via SnackBar

4. **Performance** :
   - Le chargement des abonnés se fait en arrière-plan pendant l'ouverture du dialog
   - Un indicateur de chargement est affiché pendant la récupération

5. **UX** :
   - Le bouton "Ajouter" est plus explicite que "Inviter" pour un ajout direct
   - Le toggle entre abonnés/recherche permet de garder les deux fonctionnalités accessibles
   - Les messages de confirmation sont différenciés selon le type d'action

---

## 🚀 Améliorations Futures Possibles

1. **Sélection Multiple** :
   - Ajouter des checkboxes pour sélectionner plusieurs abonnés à la fois
   - Bouton "Ajouter les sélectionnés (5)" en bas

2. **Filtres** :
   - Filtrer les abonnés par plan de collaboration
   - Filtrer par date d'abonnement

3. **Statistiques** :
   - Afficher "25 abonnés dont 10 déjà membres"
   - Griser les abonnés déjà membres du groupe

4. **Recherche dans les Abonnés** :
   - Barre de recherche pour filtrer la liste des abonnés
   - Utile pour les sociétés avec beaucoup d'abonnés

5. **Bulk Operations** :
   - "Ajouter tous mes abonnés" (avec confirmation)
   - Utile pour créer rapidement un groupe général
