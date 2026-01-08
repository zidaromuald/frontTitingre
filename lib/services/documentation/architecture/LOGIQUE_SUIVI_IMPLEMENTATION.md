# 📊 Logique de Suivi - Implémentation

## 🎯 Vue d'ensemble

Ce document décrit la logique de suivi pour les trois types d'entités dans l'application : **User**, **Société**, et **Groupe**.

---

## 1️⃣ User → User : Invitation avec Acceptation

### 📍 Fichier : `lib/iu/onglets/recherche/user_profile_page.dart`

### 🔄 Flux complet

```
User A veut suivre User B
    ↓
1. Clic sur "Envoyer une invitation"
    ↓
2. Dialog s'ouvre : message optionnel
    ↓
3. InvitationSuiviService.envoyerInvitation()
   - POST /invitations-suivi
   - receiverId: User B
   - receiverType: 'User'
   - message: "Bonjour, j'aimerais vous suivre"
    ↓
4. Invitation créée avec statut 'pending'
    ↓
5. User B reçoit la notification
    ↓
6. User B accepte ou refuse :
   - InvitationSuiviService.acceptInvitation(invitationId)
     → POST /invitations-suivi/:id/accept
     → Crée automatiquement la relation de suivi
   - InvitationSuiviService.declineInvitation(invitationId)
     → POST /invitations-suivi/:id/decline
     → Invitation refusée
    ↓
7. Si acceptée : Relation de suivi active
   Si refusée : Affiche "Invitation refusée"
```

### ✅ Implémentation

**Service utilisé** : `InvitationSuiviService`

```dart
// Envoyer l'invitation
await InvitationSuiviService.envoyerInvitation(
  receiverId: userId,
  receiverType: EntityType.user,
  message: 'Message optionnel',
);

// Accepter l'invitation (côté User B)
await InvitationSuiviService.acceptInvitation(invitationId);

// Refuser l'invitation (côté User B)
await InvitationSuiviService.declineInvitation(invitationId);
```

### 🎨 États du bouton

| État | Icône | Texte | Couleur | Action |
|------|-------|-------|---------|--------|
| **Aucune invitation** | `mail_outline` | "Envoyer une invitation" | Vert | Ouvre dialog |
| **En attente** | `hourglass_empty` | "Invitation en attente" | Orange | Aucune |
| **Refusée** | `cancel` | "Invitation refusée" | Rouge | Aucune |
| **Acceptée** | `check` | "Abonné" | Vert | Unfollow |

---

## 2️⃣ User → Société : Suivi Automatique

### 📍 Fichier : `lib/iu/onglets/recherche/societe_profile_page.dart`

### 🔄 Flux complet

```
User veut suivre une Société
    ↓
1. Clic sur "Suivre"
    ↓
2. SuivreAuthService.suivre()
   - POST /suivis
   - followedId: Société ID
   - followedType: 'Societe'
    ↓
3. Relation de suivi créée IMMÉDIATEMENT
    ↓
4. User suit maintenant la société
   - Voit les posts publics de la société
   - Reçoit les notifications
```

### ✅ Implémentation

**Service utilisé** : `SuivreAuthService`

```dart
// Suivre une société (IMMÉDIAT, pas d'acceptation)
await SuivreAuthService.suivre(
  followedId: societeId,
  followedType: EntityType.societe,
);

// Ne plus suivre
await SuivreAuthService.unfollow(
  followedId: societeId,
  followedType: EntityType.societe,
);
```

### 🎨 États du bouton

| État | Icône | Texte | Couleur | Action |
|------|-------|-------|---------|--------|
| **Pas suivi** | `add` | "Suivre" | Bleu | Suivre immédiatement |
| **Déjà suivi** | `check` | "Suivi" | Gris | Unfollow |

### 📝 Note importante

Les sociétés ont des **profils publics** par défaut. Un user peut suivre n'importe quelle société sans demander d'autorisation. C'est similaire à suivre une page d'entreprise sur LinkedIn ou Facebook.

---

## 3️⃣ User → Groupe : Dépend de la Visibilité

### 📍 Fichier : `lib/iu/onglets/recherche/groupe_profile_page.dart`

### 🔄 Flux complet

#### Cas A : Groupe PUBLIC

```
User veut rejoindre un Groupe PUBLIC
    ↓
1. Clic sur "Rejoindre le groupe"
    ↓
2. GroupeMembreService.joinGroupe()
   - POST /groupes/:id/join
    ↓
3. Membre ajouté IMMÉDIATEMENT
    ↓
4. User est maintenant membre du groupe
   - Accès aux posts du groupe
   - Peut poster dans le groupe
```

#### Cas B : Groupe PRIVÉ

```
User veut rejoindre un Groupe PRIVÉ
    ↓
1. Clic sur "Demander à rejoindre"
    ↓
2. GroupeInvitationService.demanderAdhesion()
   - POST /groupes/:id/demandes-adhesion
   - message: "Je souhaite rejoindre votre groupe"
    ↓
3. Demande créée avec statut 'pending'
    ↓
4. Admin du groupe reçoit la notification
    ↓
5. Admin accepte ou refuse :
   - GroupeInvitationService.accepterDemande(demandeId)
     → POST /groupes/demandes-adhesion/:id/accept
     → User devient membre
   - GroupeInvitationService.refuserDemande(demandeId)
     → POST /groupes/demandes-adhesion/:id/decline
     → Demande refusée
    ↓
6. Si acceptée : User devient membre
   Si refusée : Affiche "Demande refusée"
```

### ✅ Implémentation

**Services utilisés** : `GroupeMembreService` + `GroupeInvitationService`

```dart
// Vérifier la visibilité du groupe
if (groupe.visibilite == 'public') {
  // Rejoindre immédiatement
  await GroupeMembreService.joinGroupe(groupeId);
} else {
  // Envoyer une demande d'adhésion
  await GroupeInvitationService.demanderAdhesion(
    groupeId: groupeId,
    message: 'Message optionnel',
  );
}

// Accepter une demande (côté admin)
await GroupeInvitationService.acceptInvitation(invitationId);

// Refuser une demande (côté admin)
await GroupeInvitationService.declineInvitation(invitationId);

// Quitter le groupe
await GroupeMembreService.leaveGroupe(groupeId);
```

### 🎨 États du bouton

#### Groupe PUBLIC

| État | Icône | Texte | Couleur | Action |
|------|-------|-------|---------|--------|
| **Pas membre** | `group_add` | "Rejoindre le groupe" | Bleu | Join immédiat |
| **Membre** | `check` | "Membre" | Vert | Leave |
| **Groupe plein** | `block` | "Groupe plein" | Gris | Désactivé |

#### Groupe PRIVÉ

| État | Icône | Texte | Couleur | Action |
|------|-------|-------|---------|--------|
| **Aucune demande** | `mail_outline` | "Demander à rejoindre" | Bleu | Envoyer demande |
| **Demande en attente** | `hourglass_empty` | "Demande en attente" | Orange | Aucune |
| **Demande refusée** | `cancel` | "Demande refusée" | Rouge | Aucune |
| **Membre** | `check` | "Membre" | Vert | Leave |

---

## 📊 Tableau récapitulatif

| Type de suivi | Service | Endpoint | Acceptation requise | Visibilité |
|---------------|---------|----------|---------------------|------------|
| **User → User** | `InvitationSuiviService` | `/invitations-suivi` | ✅ Oui | User doit accepter |
| **User → Société** | `SuivreAuthService` | `/suivis` | ❌ Non | Public (immédiat) |
| **User → Groupe PUBLIC** | `GroupeMembreService` | `/groupes/:id/join` | ❌ Non | Public (immédiat) |
| **User → Groupe PRIVÉ** | `GroupeInvitationService` | `/groupes/:id/demandes-adhesion` | ✅ Oui | Admin doit accepter |

---

## 🔧 Fichiers modifiés

### 1. `lib/iu/onglets/recherche/user_profile_page.dart`
- ✅ Implémente `InvitationSuiviService.envoyerInvitation()`
- ✅ Affiche les états : "Envoyer une invitation", "Invitation en attente", "Invitation refusée", "Abonné"
- ✅ Dialog pour message optionnel

### 2. `lib/iu/onglets/recherche/societe_profile_page.dart`
- ✅ Utilise `SuivreAuthService.suivre()` (suivi immédiat)
- ✅ Affiche "Suivre" / "Suivi"

### 3. `lib/iu/onglets/recherche/groupe_profile_page.dart`
- ✅ Vérifie `groupe.visibilite`
- ✅ Si public → `GroupeMembreService.joinGroupe()`
- ✅ Si privé → `GroupeInvitationService.demanderAdhesion()`
- ✅ Affiche les états selon visibilité

### 4. `lib/iu/onglets/postInfo/post.dart`
- ✅ Charge dynamiquement les groupes (via `GroupeAuthService.getMyGroupes()`)
- ✅ Charge dynamiquement les sociétés suivies (via `SuivreAuthService.getMyFollowing()`)
- ✅ Permet de poster sur : Public / Groupe / Société

---

## 🎯 Logique résumée

### User → User
**Pourquoi invitation ?** Les users ont des profils privés. On demande l'autorisation avant de les suivre (comme LinkedIn).

### User → Société
**Pourquoi suivi direct ?** Les sociétés ont des profils publics. Tout le monde peut les suivre (comme une page Facebook).

### User → Groupe
**Pourquoi ça dépend ?**
- **Groupe PUBLIC** : Tout le monde peut rejoindre (comme un groupe WhatsApp public)
- **Groupe PRIVÉ** : Nécessite l'approbation d'un admin (comme un groupe privé Facebook)

---

## 📅 Date de création
**2025-12-07**

## 📝 Statut
- ✅ User → User : Implémenté
- ⚠️ User → Société : À vérifier
- ⚠️ User → Groupe : À implémenter complètement
