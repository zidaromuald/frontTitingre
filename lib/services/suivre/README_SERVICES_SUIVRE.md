# 🔗 Services de Relations - Dossier `suivre/`

## 📁 Contenu du Dossier

Ce dossier contient les **4 services de gestion des relations** entre utilisateurs et sociétés dans GestAuth.

```
lib/services/suivre/
├── suivre_auth_service.dart              # ✅ Service Suivre
├── invitation_suivi_service.dart         # ✅ Service Invitation
├── demande_abonnement_service.dart       # ✅ Service Demande Abonnement
├── abonnement_auth_service.dart          # ✅ Service Abonnement
└── README_SERVICES_SUIVRE.md             # ← Vous êtes ici
```

---

## 🎯 Les 4 Services

### 1. 🔄 suivre_auth_service.dart

**Ligne de code:** 321 lignes

**Objectif:** Relations de suivi simples et rapides

**Enums:**
- `EntityType`: user, societe

**Modèles:**
- `SuivreModel`: Représente une relation de suivi
- `AbonnementModel`: Abonnement créé lors d'un upgrade
- `PagePartenariatModel`: Page créée lors d'un upgrade

**Méthodes principales:**
```dart
// Suivre/Ne plus suivre
SuivreAuthService.suivre(followedId, followedType)
SuivreAuthService.unfollow(followedId, followedType)
SuivreAuthService.checkSuivi(followedId, followedType)

// Consulter mes suivis/followers
SuivreAuthService.getMyFollowing(type?)
SuivreAuthService.getFollowers(followedId, followedType)

// Upgrade vers abonnement (User → Societe uniquement)
SuivreAuthService.upgradeToAbonnement(societeId, planCollaboration)

// Statistiques
SuivreAuthService.getSocieteStats(societeId)
```

**Cas d'usage:**
- Suivre des influenceurs
- Suivre des entreprises intéressantes
- Réseau social simple
- Veille concurrentielle

**Participants:** User ↔ User, User ↔ Societe, Societe ↔ Societe

---

### 2. ✉️ invitation_suivi_service.dart

**Ligne de code:** 392 lignes

**Objectif:** Invitations pour créer des relations contrôlées

**Enums:**
- `InvitationSuiviStatus`: pending, accepted, declined, cancelled
- `EntityType`: user, societe

**Modèles:**
- `InvitationSuiviModel`: Représente une invitation
- `AcceptInvitationResponse`: Réponse lors de l'acceptation

**Méthodes principales:**
```dart
// Envoyer/Annuler une invitation
InvitationSuiviService.envoyerInvitation(receiverId, receiverType, message?)
InvitationSuiviService.annulerInvitation(invitationId)

// Accepter/Refuser une invitation
InvitationSuiviService.accepterInvitation(invitationId)
InvitationSuiviService.refuserInvitation(invitationId)

// Consulter mes invitations
InvitationSuiviService.getMesInvitationsEnvoyees(status?)
InvitationSuiviService.getMesInvitationsRecues(status?)
InvitationSuiviService.countInvitationsPending()
```

**Cas d'usage:**
- Réseau professionnel fermé
- Demande de connexion formelle
- Contrôle de son réseau

**Participants:** User ↔ User, User ↔ Societe, Societe ↔ Societe

**Particularité:** Crée automatiquement des relations Suivre **bidirectionnelles** lors de l'acceptation

---

### 3. 📋 demande_abonnement_service.dart

**Ligne de code:** 312 lignes

**Objectif:** Demander un abonnement premium avec permissions

**Enums:**
- `DemandeAbonnementStatus`: pending, accepted, declined, cancelled

**Modèles:**
- `DemandeAbonnementModel`: Représente une demande
- `AcceptDemandeResponse`: Réponse lors de l'acceptation (contient abonnementId, pagePartenariatId, etc.)

**Méthodes principales:**
```dart
// USER: Envoyer/Annuler une demande
DemandeAbonnementService.envoyerDemande(societeId, message?)
DemandeAbonnementService.annulerDemande(demandeId)
DemandeAbonnementService.getMesDemandesEnvoyees(status?)

// SOCIETE: Accepter/Refuser une demande
DemandeAbonnementService.accepterDemande(demandeId)  // Crée TOUT automatiquement
DemandeAbonnementService.refuserDemande(demandeId)
DemandeAbonnementService.getDemandesRecues(status?)
DemandeAbonnementService.countDemandesPending()

// Utilitaires
DemandeAbonnementService.checkDemandeExistante(societeId)
DemandeAbonnementService.getAllDemandesGrouped()
```

**Cas d'usage:**
- Partenariat professionnel
- Accès à des services premium
- Collaboration formelle

**Participants:** **User → Societe UNIQUEMENT** (sens unique)

**Transaction automatique lors de l'acceptation:**
```
accepterDemande() → Crée en UNE TRANSACTION:
  1. Suivre bidirectionnel (User ↔ Societe)
  2. Abonnement (statut: actif)
  3. Page Partenariat

Retourne: { abonnementId, pagePartenariatId, suivresCreated: 2 }
```

---

### 4. 🎯 abonnement_auth_service.dart

**Ligne de code:** 440 lignes

**Objectif:** Gérer les abonnements actifs avec permissions granulaires

**Enums:**
- `AbonnementStatut`: actif, suspendu, expire, annule
- `AbonnementPermission`: voir_profil, voir_contacts, voir_projets, messagerie, notifications

**Modèles:**
- `AbonnementModel`: Représente un abonnement
- `AbonnementStats`: Statistiques des abonnements

**Méthodes principales:**
```dart
// USER: Consulter mes abonnements
AbonnementAuthService.getMySubscriptions(statut?)
AbonnementAuthService.checkAbonnement(societeId)
AbonnementAuthService.getAbonnement(abonnementId)
AbonnementAuthService.deleteAbonnement(abonnementId)
AbonnementAuthService.getMySubscriptionStats()

// SOCIETE: Gérer mes abonnés
AbonnementAuthService.getMySubscribers(statut?)
AbonnementAuthService.updateAbonnement(abonnementId, planCollaboration?, dateFin?)
AbonnementAuthService.updatePermissions(abonnementId, permissions[])
AbonnementAuthService.suspendAbonnement(abonnementId)
AbonnementAuthService.reactivateAbonnement(abonnementId)
AbonnementAuthService.deleteAbonnement(abonnementId)
AbonnementAuthService.getMySubscriberStats()

// Utilitaires
AbonnementAuthService.isSubscribedTo(societeId)
AbonnementAuthService.getSubscriptionWithSociete(societeId)
AbonnementAuthService.permissionsToStrings(permissions[])
AbonnementAuthService.stringsToPermissions(permissions[])
```

**Cas d'usage:**
- Gestion post-création d'un partenariat
- Modification des accès
- Suspension temporaire
- Statistiques détaillées

**Participants:** User ↔ Societe (déjà validé via Demande Abonnement)

**Permissions disponibles:**
- `voir_profil`: Voir le profil complet
- `voir_contacts`: Accéder aux contacts
- `voir_projets`: Voir les projets
- `messagerie`: Envoyer des messages
- `notifications`: Recevoir des notifications

---

## 🔄 Ordre Logique d'Utilisation

```
1. SUIVRE SIMPLE
   ↓
   SuivreAuthService.suivre()
   → Relation immédiate, pas de permissions

2. INVITATION (Alternative au suivi simple)
   ↓
   InvitationSuiviService.envoyerInvitation()
   → Nécessite validation
   → Si acceptée: Suivre bidirectionnel

3. DEMANDE ABONNEMENT
   ↓
   DemandeAbonnementService.envoyerDemande()
   → User envoie une demande à une Societe
   → Societe examine et accepte
   ↓
   DemandeAbonnementService.accepterDemande()
   → Crée automatiquement:
     • Suivre bidirectionnel
     • Abonnement (statut: actif)
     • Page Partenariat

4. GESTION ABONNEMENT
   ↓
   AbonnementAuthService.*
   → Societe gère permissions, plan, suspend/réactive
   → User consulte, peut annuler
```

---

## 📊 Comparaison Rapide

| Service | Validation | Permissions | User→User | User→Societe | Societe→Societe | Bidirectionnel |
|---------|-----------|-------------|-----------|--------------|-----------------|----------------|
| **Suivre** | ❌ Immédiat | ❌ Non | ✅ | ✅ | ✅ | Optionnel |
| **Invitation** | ✅ Requise | ❌ Non | ✅ | ✅ | ✅ | ✅ Auto |
| **Demande** | ✅ Requise | ✅ Créées | ❌ | ✅ | ❌ | ✅ Auto |
| **Abonnement** | ✅ Validé | ✅ Modifiables | ❌ | ✅ | ❌ | ✅ |

---

## 🎨 Exemples d'Utilisation Rapides

### Suivre une Société (Immédiat)

```dart
await SuivreAuthService.suivre(
  followedId: 123,
  followedType: EntityType.societe,
);
```

### Envoyer une Invitation (Nécessite validation)

```dart
final invitation = await InvitationSuiviService.envoyerInvitation(
  receiverId: 123,
  receiverType: EntityType.societe,
  message: 'J\'aimerais me connecter avec vous',
);
```

### Demander un Abonnement (User → Societe)

```dart
final demande = await DemandeAbonnementService.envoyerDemande(
  societeId: 123,
  message: 'Je souhaite devenir partenaire',
);
```

### Accepter une Demande (Crée tout automatiquement)

```dart
final result = await DemandeAbonnementService.accepterDemande(demandeId);
print('Abonnement: ${result.abonnementId}');
print('Page partenariat: ${result.pagePartenariatId}');
```

### Gérer les Permissions (Société)

```dart
await AbonnementAuthService.updatePermissions(abonnementId, [
  'voir_profil',
  'voir_contacts',
  'messagerie',
]);
```

---

## 🔐 Sécurité

Tous les services utilisent automatiquement le JWT via `ApiService`:

```dart
// Vous n'avez PAS besoin de gérer manuellement le JWT!
final abonnements = await AbonnementAuthService.getMySubscriptions();
// ↑ Le token est automatiquement ajouté dans le header Authorization
```

**Backend vérifie automatiquement:**
1. Token JWT valide
2. `userType` correspond à l'endpoint (user/societe)
3. Propriété de la ressource (pour modifications)

---

## 📚 Documentation Complète

Pour plus de détails, consultez le dossier `documentation/`:

```
lib/services/documentation/
├── README.md                           # Index de la documentation
├── DEMANDE_ABONNEMENT_MAPPING.md       # Mapping détaillé du service Demande
├── ABONNEMENT_MAPPING.md               # Mapping détaillé du service Abonnement
└── SYSTEME_RELATIONS_COMPLET.md        # Vue d'ensemble du système complet
```

**Liens rapides:**
- [Documentation Demande Abonnement](../documentation/DEMANDE_ABONNEMENT_MAPPING.md)
- [Documentation Abonnement](../documentation/ABONNEMENT_MAPPING.md)
- [Système de Relations Complet](../documentation/SYSTEME_RELATIONS_COMPLET.md)

---

## ✅ Conformité Backend

**Total: 35 endpoints implémentés ✅**

| Service | Endpoints | Status |
|---------|-----------|--------|
| SuivreAuthService | 8/8 | ✅ 100% |
| InvitationSuiviService | 7/7 | ✅ 100% |
| DemandeAbonnementService | 7/7 | ✅ 100% |
| AbonnementAuthService | 13/13 | ✅ 100% |

**Tous les services sont 100% conformes aux controllers NestJS backend!**

---

## 🎯 Quelle Service Utiliser?

### Si vous voulez...

**...simplement suivre quelqu'un**
→ Utilisez `SuivreAuthService`

**...une connexion professionnelle contrôlée**
→ Utilisez `InvitationSuiviService`

**...un partenariat officiel avec permissions**
→ Utilisez `DemandeAbonnementService` (User → Societe)

**...gérer un abonnement existant**
→ Utilisez `AbonnementAuthService`

---

## 🚀 Prochaines Étapes

1. **Créer les pages UI:**
   - Page "Mes Abonnements" (User)
   - Page "Mes Abonnés" (Société)
   - Widget "Bouton Abonnement Intelligent"

2. **Implémenter les notifications:**
   - Notification quand demande acceptée
   - Notification quand permissions modifiées

3. **Ajouter les statistiques:**
   - Graphiques d'évolution
   - Rapports mensuels

---

## 🎉 Conclusion

Ce dossier contient **4 services complets et conformes** pour gérer toutes les relations entre utilisateurs et sociétés dans GestAuth.

**Total: 1465 lignes de code | 35 endpoints | 100% conforme ✅**

**Le système est prêt pour la production! 🚀**
