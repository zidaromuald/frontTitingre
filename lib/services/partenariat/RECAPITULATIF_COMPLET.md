# 📦 Récapitulatif Complet - Module Partenariat

## 🎯 Vue d'ensemble

Le module **Partenariat** est maintenant complet avec deux services principaux permettant la gestion complète des relations entre Users (producteurs) et Sociétés dans le cadre d'abonnements premium.

---

## 📁 Structure du module

```
lib/services/partenariat/
├── information_partenaire_service.dart          # Service informations partenaires
├── transaction_partenariat_service.dart         # Service transactions
├── README_INFORMATION_PARTENAIRE.md            # Documentation informations
├── README_TRANSACTION_PARTENARIAT.md           # Documentation transactions
├── EXEMPLE_UTILISATION.dart                     # Exemples informations
├── EXEMPLE_TRANSACTION.dart                     # Exemples transactions
├── IMPLEMENTATION_COMPLETE.md                   # Résumé informations
├── ARCHITECTURE.md                              # Architecture technique
└── RECAPITULATIF_COMPLET.md                    # Ce fichier
```

---

## 🔧 Services implémentés

### 1. InformationPartenaireService

**Objectif:** Partage d'informations structurées entre partenaires

**Fonctionnalités:**
- ✅ Créer des informations (User ou Société)
- ✅ Lister les informations d'une page partenaire
- ✅ Récupérer une information par ID
- ✅ Modifier ses propres informations
- ✅ Supprimer ses propres informations

**Permissions:**
- **User ET Société** peuvent créer, modifier et supprimer leurs propres informations
- Tous peuvent lire les informations de la page partenaire

**Exemple d'usage:**
```dart
// User ajoute sa localité
await InformationPartenaireService.createInformation(
  CreateInformationPartenaireDto(
    pageId: 1,
    titre: 'Localité',
    contenu: 'Sorano (Champs) Uber',
    typeInfo: 'localite',
  ),
);

// Société ajoute ses certificats
await InformationPartenaireService.createInformation(
  CreateInformationPartenaireDto(
    pageId: 1,
    titre: 'Certificats',
    contenu: 'ISO 9001, Bio',
    typeInfo: 'certificats',
  ),
);
```

---

### 2. TransactionPartenaritService

**Objectif:** Gestion des transactions commerciales avec workflow de validation

**Fonctionnalités:**
- ✅ Créer des transactions (Société uniquement)
- ✅ Lister les transactions d'une page (Société)
- ✅ Consulter transactions en attente (User)
- ✅ Compter transactions en attente (User - pour badge)
- ✅ Modifier transactions non validées (Société)
- ✅ Valider/Rejeter transactions (User)
- ✅ Supprimer transactions non validées (Société)

**Workflow:**
```
Société crée → en_attente → User valide → validee
                         ↓
                      User rejette → rejetee
```

**Permissions:**
| Action | Société | User |
|--------|---------|------|
| Créer | ✅ | ❌ |
| Modifier (si en_attente) | ✅ | ❌ |
| Supprimer (si en_attente) | ✅ | ❌ |
| Valider/Rejeter | ❌ | ✅ |
| Lire transactions page | ✅ | ❌ |
| Lire transactions en attente | ❌ | ✅ |

**Exemple d'usage:**
```dart
// Société crée une transaction
final transaction = await TransactionPartenaritService.createTransaction(
  CreateTransactionPartenaritDto(
    pageId: 1,
    userId: 5,
    periode: 'Janvier à Mars 2023',
    quantite: '2038 Kg',
    prixUnitaire: '1000 CFA',
    prixTotal: '2,038,000 CFA',
  ),
);

// User valide la transaction
await TransactionPartenaritService.validateTransaction(
  transaction.id,
  ValidateTransactionDto(valide: true, commentaire: 'Conforme'),
);
```

---

## 🔗 Endpoints Backend

### Informations Partenaires (`/informations-partenaires`)

| Méthode | Endpoint | Service Method | Restriction |
|---------|----------|----------------|-------------|
| POST | `/informations-partenaires` | `createInformation()` | ✅ User + Société |
| GET | `/informations-partenaires/page/:pageId` | `getInformationsForPage()` | ✅ User + Société |
| GET | `/informations-partenaires/:id` | `getInformationById()` | ✅ User + Société |
| PUT | `/informations-partenaires/:id` | `updateInformation()` | ⚠️ Créateur uniquement |
| DELETE | `/informations-partenaires/:id` | `deleteInformation()` | ⚠️ Créateur uniquement |

### Transactions Partenariat (`/transactions-partenariat`)

| Méthode | Endpoint | Service Method | Restriction |
|---------|----------|----------------|-------------|
| POST | `/transactions-partenariat` | `createTransaction()` | 🏢 Société |
| GET | `/transactions-partenariat/page/:pageId` | `getTransactionsForPage()` | 🏢 Société |
| GET | `/transactions-partenariat/pending` | `getPendingTransactions()` | 👤 User |
| GET | `/transactions-partenariat/pending/count` | `countPendingTransactions()` | 👤 User |
| GET | `/transactions-partenariat/:id` | `getTransactionById()` | ✅ User + Société |
| PUT | `/transactions-partenariat/:id` | `updateTransaction()` | 🏢 Société (si en_attente) |
| PUT | `/transactions-partenariat/:id/validate` | `validateTransaction()` | 👤 User |
| DELETE | `/transactions-partenariat/:id` | `deleteTransaction()` | 🏢 Société (si en_attente) |

---

## 🎨 Intégration dans SocieteDetailsPage

La page `SocieteDetailsPage` ([transaction.dart](../../iu/onglets/servicePlan/transaction.dart)) doit être mise à jour pour inclure les deux onglets:

### Structure proposée

```dart
class SocieteDetailsPage extends StatefulWidget {
  final Map<String, dynamic> societe;
  final Map<String, dynamic> categorie;
  final int pageId; // À ajouter - ID de la page partenaire

  @override
  State<SocieteDetailsPage> createState() => _SocieteDetailsPageState();
}

class _SocieteDetailsPageState extends State<SocieteDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.societe['nom']),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Transactions'),
              Tab(icon: Icon(Icons.handshake), text: 'Partenariat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Onglet 1: Transactions
            _buildTransactionTab(),

            // Onglet 2: Informations Partenariat
            InformationsPartenairePage(pageId: widget.pageId),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTab() {
    // Selon le type d'utilisateur
    final userType = await AuthBaseService.getUserType();

    if (userType == 'societe') {
      // Société: Afficher toutes les transactions + créer
      return TransactionsSocietePage(pageId: widget.pageId);
    } else {
      // User: Afficher transactions en attente à valider
      return TransactionsPendingUserPage();
    }
  }
}
```

---

## 📊 Modèles de données

### InformationPartenaireModel

```dart
{
  id: int,
  pageId: int,
  createdById: int,
  createdByType: 'User' | 'Societe',
  titre: String,
  contenu: String?,
  typeInfo: String?,  // 'localite', 'contact', 'certificats', etc.
  ordre: int?,
  createdAt: DateTime,
  updatedAt: DateTime,
  // Relations
  createdByNom: String?,
  createdByPrenom: String?,
}
```

### TransactionPartenaritModel

```dart
{
  id: int,
  pageId: int,
  societeId: int,
  userId: int,
  periode: String,         // "Janvier à Mars 2023"
  quantite: String,        // "2038 Kg"
  prixUnitaire: String,    // "1000 CFA"
  prixTotal: String,       // "2,038,000 CFA"
  statut: String,          // 'en_attente' | 'validee' | 'rejetee'
  dateValidation: DateTime?,
  commentaire: String?,
  createdAt: DateTime,
  updatedAt: DateTime,
  // Relations
  societeNom: String?,
  userNom: String?,
  userPrenom: String?,
}
```

---

## 🎯 Cas d'usage complets

### Scénario 1: Nouveau partenariat premium

```dart
// 1. User crée un abonnement premium avec une Société
final abonnement = await AbonnementAuthService.subscribe(societeId);

// 2. Backend crée automatiquement une page partenaire
final pageId = abonnement.partenairePageId;

// 3. User et Société peuvent ajouter des informations
await InformationPartenaireService.createInformation(
  CreateInformationPartenaireDto(
    pageId: pageId,
    titre: 'Localité',
    contenu: 'Sorano (Champs)',
  ),
);

// 4. Société crée une transaction pour un achat
final transaction = await TransactionPartenaritService.createTransaction(
  CreateTransactionPartenaritDto(
    pageId: pageId,
    userId: userId,
    periode: 'Janvier à Mars 2023',
    quantite: '2038 Kg',
    prixTotal: '2,038,000 CFA',
  ),
);

// 5. User reçoit notification (badge)
final count = await TransactionPartenaritService.countPendingTransactions();
// Badge: "1 transaction en attente"

// 6. User valide la transaction
await TransactionPartenaritService.validateTransaction(
  transaction.id,
  ValidateTransactionDto(valide: true),
);
```

### Scénario 2: Gestion des informations

```dart
// User consulte les informations partenariat
final infos = await InformationPartenaireService.getInformationsForPage(pageId);

for (var info in infos) {
  print('${info.titre}: ${info.contenu}');
  print('Créé par: ${info.getCreatorName()} (${info.createdByType})');

  // User peut modifier ses propres infos
  if (info.isCreatedByMe(myId, myType)) {
    await InformationPartenaireService.updateInformation(
      info.id,
      UpdateInformationPartenaireDto(contenu: 'Nouvelle valeur'),
    );
  }
}
```

---

## 🔄 Flux de navigation

### Pour les Users (IU)

```
HomePage
  ↓
ServicePage (onglet Société)
  ↓
Clique sur Société (premium)
  ↓
Modal: "Transaction / Partenariat"
  ↓
SocieteDetailsPage
  ├── Tab 1: Transactions en attente à valider
  │   └── TransactionsPendingUserPage
  └── Tab 2: Informations partenariat
      └── InformationsPartenairePage
```

### Pour les Sociétés (IS)

```
HomePage
  ↓
ServicePage (onglet Suivie)
  ↓
Clique sur User (abonné premium)
  ↓
Modal: "Transaction / Partenariat"
  ↓
SocieteDetailsPage (UserDetailsPage?)
  ├── Tab 1: Gérer les transactions
  │   └── TransactionsSocietePage
  │       - Créer transaction
  │       - Modifier (si en_attente)
  │       - Supprimer (si en_attente)
  └── Tab 2: Informations partenariat
      └── InformationsPartenairePage
```

---

## 📱 Notifications et badges

### Badge de transactions en attente (User)

```dart
// Dans ServicePage ou AppBar
class _ServicePageState extends State<ServicePage> {
  int _pendingCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();

    // Rafraîchir toutes les 30 secondes
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _loadPendingCount();
    });
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await TransactionPartenaritService.countPendingTransactions();
      if (mounted) setState(() => _pendingCount = count);
    } catch (e) {
      // Ignorer si erreur (pas un User)
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.receipt_long),
              onPressed: () => Navigator.push(...),
            ),
            if (_pendingCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$_pendingCount'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

---

## 🧪 Tests recommandés

### Tests unitaires - InformationPartenaireService

```dart
test('Créer une information partenaire', () async {
  final dto = CreateInformationPartenaireDto(
    pageId: 1,
    titre: 'Test',
    contenu: 'Contenu test',
  );

  final info = await InformationPartenaireService.createInformation(dto);
  expect(info.titre, 'Test');
});

test('Seul le créateur peut modifier', () async {
  // Créer en tant que User 1
  final info = await InformationPartenaireService.createInformation(dto);

  // Essayer de modifier en tant que User 2
  expect(
    () => InformationPartenaireService.updateInformation(info.id, updateDto),
    throwsException,
  );
});
```

### Tests unitaires - TransactionPartenaritService

```dart
test('Seule la Société peut créer une transaction', () async {
  // Connecté en tant que User
  expect(
    () => TransactionPartenaritService.createTransaction(dto),
    throwsA(contains('Seule la Société')),
  );
});

test('User peut valider une transaction', () async {
  // Créer transaction en tant que Société
  final transaction = await TransactionPartenaritService.createTransaction(dto);
  expect(transaction.statut, 'en_attente');

  // Valider en tant que User
  final validated = await TransactionPartenaritService.validateTransaction(
    transaction.id,
    ValidateTransactionDto(valide: true),
  );

  expect(validated.statut, 'validee');
  expect(validated.dateValidation, isNotNull);
});

test('Impossible de modifier une transaction validée', () async {
  // Créer et valider
  final transaction = await _createAndValidate();

  // Essayer de modifier
  expect(
    () => TransactionPartenaritService.updateTransaction(transaction.id, dto),
    throwsException,
  );
});
```

---

## 📈 Statistiques et métriques

### Données utiles à afficher

```dart
// Dashboard Société
class SocieteDashboard {
  // Nombre total de transactions
  int totalTransactions;

  // Montant total validé
  String montantTotalValide;

  // Transactions en attente
  int transactionsEnAttente;

  // Taux de validation
  double tauxValidation;

  // Informations partagées
  int informationsPartagees;
}

// Dashboard User
class UserDashboard {
  // Transactions en attente de validation
  int transactionsEnAttente;

  // Transactions validées ce mois
  int transactionsValideesMois;

  // Montant total reçu
  String montantTotal;

  // Nombre de partenariats actifs
  int partenariatsActifs;
}
```

---

## 🔐 Sécurité et bonnes pratiques

### 1. Validation côté client

```dart
// Toujours vérifier les permissions avant d'afficher les actions
final userType = await AuthBaseService.getUserType();

if (userType == 'societe') {
  // Afficher bouton "Créer transaction"
} else {
  // Afficher bouton "Valider transactions"
}
```

### 2. Gestion des erreurs

```dart
try {
  await TransactionPartenaritService.createTransaction(dto);
} catch (e) {
  if (e.toString().contains('ForbiddenException')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action non autorisée')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}
```

### 3. Vérification avant modification

```dart
// Toujours vérifier le statut avant de modifier
final transaction = await TransactionPartenaritService.getTransactionById(id);

if (transaction.isValidee() || transaction.isRejetee()) {
  // Désactiver les boutons de modification
  return;
}

// Afficher boutons de modification
```

---

## 🎯 Checklist finale

### InformationPartenaireService
- [x] Service créé avec toutes les méthodes CRUD
- [x] Modèle de données complet avec méthodes utilitaires
- [x] DTOs pour création et modification
- [x] Documentation complète
- [x] Exemples d'utilisation avec widgets
- [ ] Intégration dans SocieteDetailsPage (à faire)
- [ ] Tests unitaires (à faire)

### TransactionPartenaritService
- [x] Service créé avec workflow de validation
- [x] Modèle de données avec statuts et méthodes utilitaires
- [x] DTOs pour création, modification et validation
- [x] Documentation complète
- [x] Exemples d'utilisation avec widgets
- [x] Widgets complets pour Société et User
- [ ] Intégration dans SocieteDetailsPage (à faire)
- [ ] Badge de notification (à faire)
- [ ] Tests unitaires (à faire)

---

## 🚀 Prochaines étapes

1. **Déterminer le pageId:**
   - Comment est créée la "page partenaire" ?
   - Est-ce automatique lors de la création d'un abonnement ?
   - Où stocker le `pageId` ?

2. **Intégrer dans SocieteDetailsPage:**
   - Modifier la page existante pour inclure les deux onglets
   - Passer le `pageId` en paramètre
   - Adapter selon le type d'utilisateur (User/Société)

3. **Ajouter le badge de notification:**
   - Implémenter le compteur de transactions en attente
   - Afficher dans l'AppBar ou sur l'icône ServicePlan
   - Rafraîchir périodiquement

4. **Tester avec le backend:**
   - Vérifier tous les endpoints
   - Tester les permissions
   - Valider le workflow complet

5. **Améliorer l'UX:**
   - Ajouter des animations
   - Améliorer les messages d'erreur
   - Ajouter des confirmations

---

**Date de création:** 2025-12-13
**Version:** 1.0.0
**Statut:** ✅ Services complets - Prêts pour intégration UI
