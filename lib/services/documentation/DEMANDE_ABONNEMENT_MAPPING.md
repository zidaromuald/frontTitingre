# Mapping Backend NestJS ↔️ Frontend Flutter (Demandes d'Abonnement)

## ✅ CONFORMITÉ: 100%

Le service `demande_abonnement_service.dart` correspond **parfaitement** au controller backend.

---

## 📋 Mapping Complet des Endpoints

### Endpoints USER (Envoi de demandes)

| Endpoint Backend | Méthode Dart | Statut |
|-----------------|--------------|--------|
| `POST /demandes-abonnement` | `envoyerDemande()` | ✅ |
| `DELETE /demandes-abonnement/:id` | `annulerDemande()` | ✅ |
| `GET /demandes-abonnement/sent` | `getMesDemandesEnvoyees()` | ✅ |

### Endpoints SOCIETE (Gestion des demandes)

| Endpoint Backend | Méthode Dart | Statut |
|-----------------|--------------|--------|
| `PUT /demandes-abonnement/:id/accept` | `accepterDemande()` | ✅ |
| `PUT /demandes-abonnement/:id/decline` | `refuserDemande()` | ✅ |
| `GET /demandes-abonnement/received` | `getDemandesRecues()` | ✅ |
| `GET /demandes-abonnement/pending/count` | `countDemandesPending()` | ✅ |

**Total: 7/7 endpoints ✅**

---

## 🎯 Architecture du Système d'Abonnement

### Workflow Complet

```
┌─────────────────────────────────────────────────────────┐
│                    UTILISATEUR                           │
└─────────────────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    Envoyer         Annuler         Consulter
    demande         demande         demandes
         │               │               │
         └───────────────┴───────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                 Backend NestJS                           │
│                                                          │
│  Table: demandes_abonnement                              │
│  ├─ id                                                   │
│  ├─ user_id                                              │
│  ├─ societe_id                                           │
│  ├─ status (pending/accepted/declined/cancelled)         │
│  ├─ message                                              │
│  └─ responded_at                                         │
└─────────────────────────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    Accepter        Refuser         Consulter
    demande         demande         demandes
         │               │               │
         └───────────────┴───────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     SOCIÉTÉ                              │
└─────────────────────────────────────────────────────────┘
```

---

## 🔐 Permissions et Guards

### Backend: JwtAuthGuard + Vérifications

```typescript
@Controller('demandes-abonnement')
@UseGuards(JwtAuthGuard) // Authentification requise
export class DemandeAbonnementController {

  @Post()
  async envoyerDemande(@CurrentUser() user: any) {
    // ✅ Vérification: userType === 'user'
    if (user.userType !== 'user') {
      throw new UnauthorizedException('Seuls les utilisateurs...');
    }
  }

  @Put(':id/accept')
  async accepterDemande(@CurrentUser() user: any) {
    // ✅ Vérification: userType === 'societe'
    if (user.userType !== 'societe') {
      throw new UnauthorizedException('Seules les sociétés...');
    }
  }
}
```

### Flutter: JWT Automatique

```dart
// Le service envoie automatiquement le JWT via ApiService
final demande = await DemandeAbonnementService.envoyerDemande(
  societeId: 123,
  message: 'Je souhaite m\'abonner',
);

// Le backend vérifie automatiquement:
// 1. Token JWT valide
// 2. userType correspond à l'endpoint
```

---

## 💡 Cas d'Usage

### 1. Utilisateur: Envoyer une Demande

```dart
import 'package:flutter/material.dart';

class SocieteProfilePage extends StatelessWidget {
  final int societeId;

  Future<void> envoyerDemande(BuildContext context) async {
    try {
      final demande = await DemandeAbonnementService.envoyerDemande(
        societeId: societeId,
        message: 'Bonjour, je souhaite devenir partenaire de votre société.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande envoyée avec succès!')),
      );

      print('Demande ID: ${demande.id}');
      print('Statut: ${demande.status.value}');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil Société')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => envoyerDemande(context),
          child: Text('Envoyer une demande d\'abonnement'),
        ),
      ),
    );
  }
}
```

---

### 2. Utilisateur: Voir Mes Demandes Envoyées

```dart
class MesDemandesPage extends StatefulWidget {
  @override
  _MesDemandesPageState createState() => _MesDemandesPageState();
}

class _MesDemandesPageState extends State<MesDemandesPage> {
  List<DemandeAbonnementModel> demandes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDemandes();
  }

  Future<void> loadDemandes() async {
    try {
      final result = await DemandeAbonnementService.getMesDemandesEnvoyees(
        status: DemandeAbonnementStatus.pending, // Ou null pour toutes
      );

      setState(() {
        demandes = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Erreur: $e');
    }
  }

  Future<void> annulerDemande(int demandeId) async {
    try {
      await DemandeAbonnementService.annulerDemande(demandeId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande annulée')),
      );

      loadDemandes(); // Recharger la liste
    } catch (e) {
      print('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: demandes.length,
      itemBuilder: (context, index) {
        final demande = demandes[index];

        return ListTile(
          title: Text('Société #${demande.societeId}'),
          subtitle: Text('Statut: ${demande.status.value}'),
          trailing: demande.isPending()
              ? IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () => annulerDemande(demande.id),
                )
              : null,
        );
      },
    );
  }
}
```

---

### 3. Société: Voir et Gérer les Demandes Reçues

```dart
class DemandesRecuesPage extends StatefulWidget {
  @override
  _DemandesRecuesPageState createState() => _DemandesRecuesPageState();
}

class _DemandesRecuesPageState extends State<DemandesRecuesPage> {
  List<DemandeAbonnementModel> demandes = [];
  int pendingCount = 0;

  @override
  void initState() {
    super.initState();
    loadDemandes();
    loadPendingCount();
  }

  Future<void> loadDemandes() async {
    try {
      final result = await DemandeAbonnementService.getDemandesRecues(
        status: DemandeAbonnementStatus.pending,
      );

      setState(() => demandes = result);
    } catch (e) {
      print('Erreur: $e');
    }
  }

  Future<void> loadPendingCount() async {
    try {
      final count = await DemandeAbonnementService.countDemandesPending();
      setState(() => pendingCount = count);
    } catch (e) {
      print('Erreur: $e');
    }
  }

  Future<void> accepterDemande(int demandeId) async {
    try {
      final result = await DemandeAbonnementService.accepterDemande(demandeId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demande acceptée! '
            'Abonnement créé (ID: ${result.abonnementId}), '
            'Page partenariat créée (ID: ${result.pagePartenariatId})',
          ),
        ),
      );

      loadDemandes(); // Recharger
      loadPendingCount(); // Mettre à jour le compteur
    } catch (e) {
      print('Erreur: $e');
    }
  }

  Future<void> refuserDemande(int demandeId) async {
    try {
      await DemandeAbonnementService.refuserDemande(demandeId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande refusée')),
      );

      loadDemandes(); // Recharger
      loadPendingCount();
    } catch (e) {
      print('Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demandes d\'abonnement ($pendingCount en attente)'),
      ),
      body: ListView.builder(
        itemCount: demandes.length,
        itemBuilder: (context, index) {
          final demande = demandes[index];

          return Card(
            child: ListTile(
              title: Text('Utilisateur #${demande.userId}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (demande.message != null) Text(demande.message!),
                  Text('Envoyée le: ${demande.createdAt}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => accepterDemande(demande.id),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => refuserDemande(demande.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## 🔄 Workflow d'Acceptation de Demande

### Backend: Transaction Complexe

Quand une société **accepte** une demande, le backend crée **automatiquement**:

```typescript
@Put(':id/accept')
async accepterDemande(id: number, societeId: number) {
  return await this.demandeService.accepterDemande(id, societeId);

  // Cette méthode crée en UNE SEULE TRANSACTION:
  // 1. Met à jour la demande (status = 'accepted')
  // 2. Crée une relation Suivre (bidirectionnelle)
  // 3. Crée un Abonnement
  // 4. Crée une PagePartenariat

  // Retourne tout:
  // {
  //   demande: { ... },
  //   suivres_created: 2,
  //   abonnement_id: 123,
  //   page_partenariat_id: 456
  // }
}
```

### Flutter: Appel Simple

```dart
// 1 seul appel, tout est créé automatiquement!
final result = await DemandeAbonnementService.accepterDemande(demandeId);

print('Demande acceptée!');
print('Abonnement créé: ${result.abonnementId}');
print('Page partenariat: ${result.pagePartenariatId}');
print('Relations suivre créées: ${result.suivresCreated}');
```

---

## 📊 États d'une Demande

```
┌──────────────────────────────────────────┐
│              PENDING                      │
│  (Demande envoyée, en attente)           │
└──────────────────────────────────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ACCEPTED │ │DECLINED │ │CANCELLED│
│         │ │         │ │         │
│(Société)│ │(Société)│ │  (User) │
└─────────┘ └─────────┘ └─────────┘
     │
     └──> Crée automatiquement:
          - Suivre (bidirectionnel)
          - Abonnement
          - PagePartenariat
```

---

## 🎨 Widget Intelligent: Bouton Dynamique

```dart
class BoutonAbonnementIntelligent extends StatefulWidget {
  final int societeId;

  @override
  _BoutonAbonnementIntelligentState createState() => _BoutonAbonnementIntelligentState();
}

class _BoutonAbonnementIntelligentState extends State<BoutonAbonnementIntelligent> {
  DemandeAbonnementModel? demandeExistante;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkDemande();
  }

  Future<void> checkDemande() async {
    final demande = await DemandeAbonnementService.checkDemandeExistante(
      widget.societeId,
    );

    setState(() {
      demandeExistante = demande;
      isLoading = false;
    });
  }

  Future<void> envoyerDemande() async {
    final demande = await DemandeAbonnementService.envoyerDemande(
      societeId: widget.societeId,
    );

    setState(() => demandeExistante = demande);
  }

  Future<void> annulerDemande() async {
    await DemandeAbonnementService.annulerDemande(demandeExistante!.id);
    setState(() => demandeExistante = null);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CircularProgressIndicator();
    }

    // Pas de demande en cours
    if (demandeExistante == null) {
      return ElevatedButton.icon(
        icon: Icon(Icons.send),
        label: Text('Demander l\'abonnement'),
        onPressed: envoyerDemande,
      );
    }

    // Demande en attente
    if (demandeExistante!.isPending()) {
      return ElevatedButton.icon(
        icon: Icon(Icons.pending),
        label: Text('Demande en attente...'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        onPressed: annulerDemande, // Permet d'annuler
      );
    }

    // Demande acceptée
    if (demandeExistante!.isAccepted()) {
      return ElevatedButton.icon(
        icon: Icon(Icons.check_circle),
        label: Text('Abonné'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        onPressed: null, // Désactivé
      );
    }

    // Demande refusée
    return ElevatedButton.icon(
      icon: Icon(Icons.cancel),
      label: Text('Demande refusée'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      onPressed: envoyerDemande, // Permet de renvoyer
    );
  }
}
```

---

## ✅ Checklist de Fonctionnalités

### Côté USER
- [x] Envoyer une demande d'abonnement ✅
- [x] Annuler une demande envoyée ✅
- [x] Voir mes demandes envoyées (filtrées par statut) ✅
- [x] Vérifier si une demande existe déjà ✅

### Côté SOCIÉTÉ
- [x] Accepter une demande (crée tout automatiquement) ✅
- [x] Refuser une demande ✅
- [x] Voir les demandes reçues (filtrées par statut) ✅
- [x] Compter les demandes en attente ✅

**Total: 8/8 fonctionnalités ✅**

---

## 🎯 Conclusion

**Conformité: 100% ✅**

Le service `demande_abonnement_service.dart` est **parfaitement aligné** avec le controller backend:

- ✅ 7 endpoints correctement mappés
- ✅ 1 enum (DemandeAbonnementStatus)
- ✅ 2 modèles (DemandeAbonnementModel, AcceptDemandeResponse)
- ✅ Permissions respectées (user vs societe)
- ✅ Méthodes utilitaires ajoutées
- ✅ Exemples complets pour chaque cas d'usage

Le système est **prêt à l'emploi** pour gérer le workflow complet des demandes d'abonnement! 🚀


🔄 Service 1: SuivreAuthService
Correspondance avec SuivreController
Route NestJS	Méthode Controller	Méthode Flutter	Status
POST /suivis	suivre(@Body() dto)	suivre()	✅ OK
DELETE /suivis/:type/:id	unfollow(@Param() type, id)	unfollow()	✅ OK
PUT /suivis/:type/:id	updateSuivi(@Param(), @Body())	updateSuivi()	✅ OK
GET /suivis/:type/:id/check	checkSuivi(@Param())	checkSuivi()	✅ OK
GET /suivis/my-following?type=	getMyFollowing(@Query())	getMyFollowing()	✅ OK
GET /suivis/:type/:id/followers	getFollowers(@Param())	getFollowers()	✅ OK
POST /suivis/upgrade-to-abonnement	upgradeToAbonnement(@Body())	upgradeToAbonnement()	✅ OK
GET /suivis/societe/:id/stats	getSocieteStats(@Param())	getSocieteStats()	✅ OK
Exemples d'utilisation
1. Suivre une entité
// User suit un autre User
await SuivreAuthService.suivre(
  followedId: 123,
  followedType: EntityType.user,
);

// User suit une Societe
await SuivreAuthService.suivre(
  followedId: 456,
  followedType: EntityType.societe,
);
Requête HTTP :
POST /suivis
Authorization: Bearer eyJhbGc...
Body: {
  "followed_id": 123,
  "followed_type": "User"
}
Réponse :
{
  "success": true,
  "message": "Vous suivez maintenant cet utilisateur",
  "data": {
    "user_id": 5,
    "user_type": "User",
    "followed_id": 123,
    "followed_type": "User",
    "notifications_actives": true,
    "score_engagement": 0
  }
}
2. Ne plus suivre
await SuivreAuthService.unfollow(
  followedId: 123,
  followedType: EntityType.user,
);
Requête HTTP :
DELETE /suivis/User/123
Authorization: Bearer eyJhbGc...
3. Vérifier si je suis une entité
final estSuivi = await SuivreAuthService.checkSuivi(
  followedId: 123,
  followedType: EntityType.societe,
);

if (estSuivi) {
  // Afficher bouton "Ne plus suivre"
} else {
  // Afficher bouton "Suivre"
}
Requête HTTP :
GET /suivis/Societe/123/check
Authorization: Bearer eyJhbGc...
Réponse :
{
  "success": true,
  "data": {
    "is_suivant": true
  }
}
4. Récupérer mes suivis
// Tous mes suivis (Users + Societes)
final tousMesSuivis = await SuivreAuthService.getMyFollowing();

// Uniquement les Users que je suis
final usersSeuls = await SuivreAuthService.getMyFollowing(
  type: EntityType.user,
);

// Uniquement les Societes que je suis
final societesSeules = await SuivreAuthService.getMyFollowing(
  type: EntityType.societe,
);
Requête HTTP :
GET /suivis/my-following?type=User
Authorization: Bearer eyJhbGc...
Réponse :
{
  "success": true,
  "data": [
    {
      "user_id": 5,
      "followed_id": 10,
      "followed_type": "User",
      "notifications_actives": true,
      "score_engagement": 25
    },
    ...
  ],
  "meta": {
    "count": 15,
    "type": "User"
  }
}
5. Upgrade vers abonnement (User → Societe UNIQUEMENT)
try {
  final result = await SuivreAuthService.upgradeToAbonnement(
    societeId: 456,
    planCollaboration: 'Premium',
  );

  final abonnement = result['abonnement'] as AbonnementModel;
  final pagePartenariat = result['page_partenariat'] as PagePartenariatModel;

  print('Abonnement créé: ${abonnement.id}');
  print('Page partenariat: ${pagePartenariat.titre}');
} catch (e) {
  // Erreur: Seuls les Users peuvent upgrader
  print('Erreur: $e');
}
Requête HTTP :
POST /suivis/upgrade-to-abonnement
Authorization: Bearer <user_token>
Body: {
  "societe_id": 456,
  "plan_collaboration": "Premium"
}
Backend vérifie :
if (user.userType !== 'user') {
  throw new UnauthorizedException('Seuls les utilisateurs peuvent upgrader');
}
Réponse :
{
  "success": true,
  "message": "Abonnement créé avec succès. Votre page partenariat est disponible.",
  "data": {
    "abonnement": {
      "id": 100,
      "statut": "actif",
      "plan_collaboration": "Premium"
    },
    "page_partenariat": {
      "id": 200,
      "titre": "Partenariat User #5 - Societe #456",
      "visibilite": "public"
    }
  }
}
📨 Service 2: InvitationSuiviService
Correspondance avec InvitationSuiviController
Route NestJS	Méthode Controller	Méthode Flutter	Status
POST /invitations-suivi	envoyerInvitation(@Body())	envoyerInvitation()	✅ OK
PUT /invitations-suivi/:id/accept	accepterInvitation(@Param())	accepterInvitation()	✅ OK
PUT /invitations-suivi/:id/decline	refuserInvitation(@Param())	refuserInvitation()	✅ OK
DELETE /invitations-suivi/:id	annulerInvitation(@Param())	annulerInvitation()	✅ OK
GET /invitations-suivi/sent?status=	getMesInvitationsEnvoyees(@Query())	getMesInvitationsEnvoyees()	✅ OK
GET /invitations-suivi/received?status=	getMesInvitationsRecues(@Query())	getMesInvitationsRecues()	✅ OK
GET /invitations-suivi/pending/count	countInvitationsPending()	countInvitationsPending()	✅ OK
Exemples d'utilisation
1. Envoyer une invitation
final invitation = await InvitationSuiviService.envoyerInvitation(
  receiverId: 789,
  receiverType: EntityType.societe,
  message: 'J\'aimerais suivre votre entreprise',
);

print('Invitation envoyée: ${invitation.id}');
Requête HTTP :
POST /invitations-suivi
Authorization: Bearer eyJhbGc...
Body: {
  "receiver_id": 789,
  "receiver_type": "Societe",
  "message": "J'aimerais suivre votre entreprise"
}
2. Accepter une invitation
final response = await InvitationSuiviService.accepterInvitation(100);

print('Invitation acceptée: ${response.invitation.id}');
print('Connexions créées: ${response.connexionsCreees}'); // 2 (bidirectionnel)
Backend crée automatiquement :
Suivre A → B
Suivre B → A (bidirectionnel)
Requête HTTP :
PUT /invitations-suivi/100/accept
Authorization: Bearer eyJhbGc...
Réponse :
{
  "success": true,
  "message": "Invitation acceptée. Vous êtes maintenant connectés !",
  "data": {
    "invitation": { ... },
    "connexions_creees": 2
  }
}
3. Compter les invitations en attente
final count = await InvitationSuiviService.countInvitationsPending();

// Afficher badge avec le nombre
Badge(
  label: Text('$count'),
  child: Icon(Icons.notifications),
);
Requête HTTP :
GET /invitations-suivi/pending/count
Authorization: Bearer eyJhbGc...
Réponse :
{
  "success": true,
  "data": {
    "count": 5
  }
}
🎯 Workflow complet : User suit une Societe
┌──────────────────────────────────────────────────────────┐
│ 1. User consulte le profil d'une Societe                │
└──────────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ 2. Vérifier si déjà suivi                                │
│    final estSuivi = await SuivreAuthService.checkSuivi() │
└──────────────────────────────────────────────────────────┘
                        ↓
        ┌───────────────┴───────────────┐
        │                               │
    ✅ Déjà suivi                  ❌ Pas encore suivi
        │                               │
        ↓                               ↓
   Afficher "Ne plus suivre"      Afficher "Suivre"
        │                               │
        │                               ↓
        │          ┌──────────────────────────────────────┐
        │          │ 3. User clique sur "Suivre"          │
        │          │    await SuivreAuthService.suivre()  │
        │          └──────────────────────────────────────┘
        │                               │
        │                               ↓
        │          ┌──────────────────────────────────────┐
        │          │ 4. Relation Suivre créée             │
        │          │    User → Societe                    │
        │          └──────────────────────────────────────┘
        │                               │
        └───────────────┬───────────────┘
                        ↓
┌──────────────────────────────────────────────────────────┐
│ 5. User peut upgrader vers abonnement                   │
│    await SuivreAuthService.upgradeToAbonnement()        │
│    → Crée Abonnement + PagePartenariat                  │
└──────────────────────────────────────────────────────────┘
✅ Résumé
Service	Routes	Status
SuivreAuthService	8/8	✅ 100% conforme
InvitationSuiviService	7/7	✅ 100% conforme
