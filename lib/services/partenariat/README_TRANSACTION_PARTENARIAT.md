# 💰 Service de Transactions Partenariat

## Vue d'ensemble

Le service `TransactionPartenaritService` gère les transactions entre les utilisateurs (producteurs) et les sociétés dans le cadre d'un partenariat premium. Ce service implémente un workflow de validation où:
- La **Société** crée et gère les transactions
- L'**User** valide ou rejette les transactions

---

## 🎯 Workflow de transaction

```
┌─────────────────────────────────────────────────────────────┐
│                  SOCIÉTÉ (Créateur)                         │
├─────────────────────────────────────────────────────────────┤
│ 1. Crée une transaction                                     │
│    - Période: "Janvier à Mars 2023"                         │
│    - Quantité: "2038 Kg"                                    │
│    - Prix unitaire: "1000 CFA"                              │
│    - Prix total: "2,038,000 CFA"                            │
│                                                             │
│ 2. Peut modifier la transaction (si pas validée)           │
│ 3. Peut supprimer la transaction (si pas validée)          │
└─────────────────────────────────────────────────────────────┘
                            ↓
                  Statut: "en_attente"
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    USER (Validateur)                        │
├─────────────────────────────────────────────────────────────┤
│ 1. Reçoit notification de nouvelle transaction             │
│ 2. Consulte les transactions en attente                    │
│ 3. Valide ✅ ou Rejette ❌ la transaction                   │
│    - Peut ajouter un commentaire                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
              Statut: "validee" ou "rejetee"
```

---

## 📁 Emplacement

```
lib/services/partenariat/
└── transaction_partenariat_service.dart
```

---

## 🔐 Règles de permissions

### SOCIÉTÉ (Societe)

| Action | Permission | Condition |
|--------|-----------|-----------|
| Créer transaction | ✅ | Toujours |
| Lire transactions page | ✅ | Sa propre page |
| Modifier transaction | ✅ | Si statut = "en_attente" |
| Supprimer transaction | ✅ | Si statut = "en_attente" |
| Valider transaction | ❌ | Interdit |

### USER (Producteur)

| Action | Permission | Condition |
|--------|-----------|-----------|
| Créer transaction | ❌ | Interdit |
| Lire transactions en attente | ✅ | Ses propres transactions |
| Compter transactions en attente | ✅ | Badge notification |
| Modifier transaction | ❌ | Interdit |
| Supprimer transaction | ❌ | Interdit |
| Valider transaction | ✅ | Si transaction le concerne |

---

## 🎨 Fonctionnalités

### 1. Créer une transaction (Société uniquement)

```dart
final dto = CreateTransactionPartenaritDto(
  pageId: 1,
  userId: 5,  // ID du producteur
  periode: 'Janvier à Mars 2023',
  quantite: '2038 Kg',
  prixUnitaire: '1000 CFA',
  prixTotal: '2,038,000 CFA',
  commentaire: 'Transaction trimestrielle',
);

final transaction = await TransactionPartenaritService.createTransaction(dto);
print('Transaction créée: ${transaction.id}');
```

### 2. Récupérer les transactions d'une page (Société)

```dart
// Société récupère toutes les transactions de sa page partenaire
final transactions = await TransactionPartenaritService
    .getTransactionsForPage(pageId: 1);

for (var transaction in transactions) {
  print('${transaction.periode}: ${transaction.prixTotal}');
  print('Statut: ${transaction.getStatusLabel()}');
}
```

### 3. Récupérer les transactions en attente (User)

```dart
// User récupère ses transactions en attente de validation
final pendingTransactions = await TransactionPartenaritService
    .getPendingTransactions();

for (var transaction in pendingTransactions) {
  print('Transaction de ${transaction.societeNom}');
  print('Montant: ${transaction.prixTotal}');
  print('Période: ${transaction.periode}');
}
```

### 4. Compter les transactions en attente (User)

```dart
// Afficher un badge de notification
final count = await TransactionPartenaritService.countPendingTransactions();
print('$count transactions en attente');

// Afficher badge dans l'UI
if (count > 0) {
  // Afficher badge avec le nombre
}
```

### 5. Valider une transaction (User)

```dart
// User valide la transaction
final dto = ValidateTransactionDto(
  valide: true,
  commentaire: 'Transaction conforme, validée',
);

final validatedTransaction = await TransactionPartenaritService
    .validateTransaction(transactionId, dto);

print('Transaction validée: ${validatedTransaction.statut}');
```

### 6. Rejeter une transaction (User)

```dart
// User rejette la transaction
final dto = ValidateTransactionDto(
  valide: false,
  commentaire: 'Quantité incorrecte',
);

final rejectedTransaction = await TransactionPartenaritService
    .validateTransaction(transactionId, dto);

print('Transaction rejetée: ${rejectedTransaction.statut}');
```

### 7. Modifier une transaction (Société)

```dart
// Société modifie une transaction non validée
final dto = UpdateTransactionPartenaritDto(
  quantite: '2100 Kg',
  prixTotal: '2,100,000 CFA',
  commentaire: 'Correction de la quantité',
);

final updated = await TransactionPartenaritService
    .updateTransaction(transactionId, dto);
```

### 8. Supprimer une transaction (Société)

```dart
// Société supprime une transaction non validée
await TransactionPartenaritService.deleteTransaction(transactionId);
print('Transaction supprimée');
```

---

## 📊 Modèle de données

### TransactionPartenaritModel

```dart
class TransactionPartenaritModel {
  final int id;
  final int pageId;
  final int societeId;
  final int userId;
  final String periode;          // "Janvier à Mars 2023"
  final String quantite;         // "2038 Kg"
  final String prixUnitaire;     // "1000 CFA"
  final String prixTotal;        // "2,038,000 CFA"
  final String statut;           // 'en_attente' | 'validee' | 'rejetee'
  final DateTime? dateValidation;
  final String? commentaire;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relations
  final String? societeNom;
  final String? societeSecteur;
  final String? userNom;
  final String? userPrenom;
  final String? userEmail;
}
```

### Méthodes utilitaires

```dart
// Vérifier le statut
bool isEnAttente = transaction.isEnAttente();
bool isValidee = transaction.isValidee();
bool isRejetee = transaction.isRejetee();

// Obtenir le nom du user
String userName = transaction.getUserName();

// Obtenir la couleur du statut (pour l'UI)
int color = transaction.getStatusColor();
// en_attente: 0xFFFFA500 (Orange)
// validee: 0xFF28A745 (Vert)
// rejetee: 0xFFDC3545 (Rouge)

// Obtenir le libellé du statut
String label = transaction.getStatusLabel();
// "En attente" | "Validée" | "Rejetée"
```

---

## 🔄 Statuts de transaction

| Statut | Description | Actions possibles |
|--------|-------------|-------------------|
| `en_attente` | Transaction créée, en attente de validation | Société: Modifier, Supprimer<br>User: Valider, Rejeter |
| `validee` | Transaction validée par le User | Aucune modification possible |
| `rejetee` | Transaction rejetée par le User | Aucune modification possible |

---

## 🎨 Intégration dans l'UI

### Page Transaction pour Société (SocieteDetailsPage)

```dart
class TransactionTabContent extends StatefulWidget {
  final int pageId;

  @override
  State<TransactionTabContent> createState() => _TransactionTabContentState();
}

class _TransactionTabContentState extends State<TransactionTabContent> {
  List<TransactionPartenaritModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await TransactionPartenaritService
          .getTransactionsForPage(widget.pageId);

      setState(() => _transactions = transactions);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bouton "Ajouter transaction" (Société uniquement)
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('Nouvelle transaction'),
          onPressed: _showCreateTransactionDialog,
        ),

        // Liste des transactions
        Expanded(
          child: ListView.builder(
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return TransactionCard(transaction: transaction);
            },
          ),
        ),
      ],
    );
  }
}
```

### Badge de notification pour User

```dart
class ServicePage extends StatefulWidget {
  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await TransactionPartenaritService.countPendingTransactions();
      setState(() => _pendingCount = count);
    } catch (e) {
      // Ignorer si erreur (probablement pas un User)
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Services'),
      actions: [
        // Badge de notification
        if (_pendingCount > 0)
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.receipt_long),
                onPressed: () => Navigator.push(...),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_pendingCount',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
```

### Dialogue de validation pour User

```dart
void _showValidationDialog(TransactionPartenaritModel transaction) {
  final commentaireController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Valider la transaction'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Période: ${transaction.periode}'),
          Text('Quantité: ${transaction.quantite}'),
          Text('Prix total: ${transaction.prixTotal}'),
          SizedBox(height: 16),
          TextField(
            controller: commentaireController,
            decoration: InputDecoration(
              labelText: 'Commentaire (optionnel)',
              hintText: 'Ajouter un commentaire...',
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        // Rejeter
        TextButton(
          onPressed: () async {
            final dto = ValidateTransactionDto(
              valide: false,
              commentaire: commentaireController.text,
            );

            await TransactionPartenaritService.validateTransaction(
              transaction.id,
              dto,
            );

            Navigator.pop(context);
            _loadTransactions(); // Refresh
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('Rejeter'),
        ),

        // Valider
        ElevatedButton(
          onPressed: () async {
            final dto = ValidateTransactionDto(
              valide: true,
              commentaire: commentaireController.text,
            );

            await TransactionPartenaritService.validateTransaction(
              transaction.id,
              dto,
            );

            Navigator.pop(context);
            _loadTransactions(); // Refresh
          },
          child: Text('Valider'),
        ),
      ],
    ),
  );
}
```

---

## 🔗 Endpoints Backend

### Base URL: `/transactions-partenariat`

| Méthode | Endpoint | Description | Restriction |
|---------|----------|-------------|-------------|
| `POST` | `/transactions-partenariat` | Créer une transaction | 🏢 Société |
| `GET` | `/transactions-partenariat/page/:pageId` | Lister transactions page | 🏢 Société |
| `GET` | `/transactions-partenariat/pending` | Transactions en attente | 👤 User |
| `GET` | `/transactions-partenariat/pending/count` | Compter en attente | 👤 User |
| `GET` | `/transactions-partenariat/:id` | Récupérer par ID | ✅ Tous |
| `PUT` | `/transactions-partenariat/:id` | Modifier | 🏢 Société (si pas validée) |
| `PUT` | `/transactions-partenariat/:id/validate` | Valider/Rejeter | 👤 User |
| `DELETE` | `/transactions-partenariat/:id` | Supprimer | 🏢 Société (si pas validée) |

---

## ⚠️ Gestion des erreurs

### Erreurs courantes

```dart
try {
  await TransactionPartenaritService.createTransaction(dto);
} catch (e) {
  if (e.toString().contains('ForbiddenException')) {
    // Seule la Société peut créer des transactions
    print('❌ Vous n\'êtes pas autorisé à créer des transactions');
  } else if (e.toString().contains('401')) {
    // Non authentifié
    print('❌ Vous devez être connecté');
  } else {
    print('❌ Erreur: $e');
  }
}
```

### Vérification avant modification

```dart
// Vérifier le statut avant de modifier
final transaction = await TransactionPartenaritService.getTransactionById(id);

if (transaction.isValidee() || transaction.isRejetee()) {
  print('❌ Cette transaction ne peut plus être modifiée');
  return;
}

// Modifier si en attente
await TransactionPartenaritService.updateTransaction(id, dto);
```

---

## 📈 Cas d'usage complets

### Scénario 1: Société crée une transaction

```dart
// 1. Société crée une nouvelle transaction pour un producteur
final dto = CreateTransactionPartenaritDto(
  pageId: partenairePageId,
  userId: producteurId,
  periode: 'Janvier à Mars 2023',
  quantite: '2038 Kg',
  prixUnitaire: '1000 CFA',
  prixTotal: '2,038,000 CFA',
  commentaire: 'Achat de cacao première récolte',
);

final transaction = await TransactionPartenaritService.createTransaction(dto);
print('✅ Transaction créée - ID: ${transaction.id}');
print('📧 Notification envoyée au producteur');
```

### Scénario 2: User consulte et valide

```dart
// 1. User reçoit notification (badge)
final count = await TransactionPartenaritService.countPendingTransactions();
print('🔔 Vous avez $count transaction(s) en attente');

// 2. User consulte les détails
final pendingTransactions = await TransactionPartenaritService
    .getPendingTransactions();

for (var transaction in pendingTransactions) {
  print('Transaction #${transaction.id}');
  print('Société: ${transaction.societeNom}');
  print('Période: ${transaction.periode}');
  print('Montant: ${transaction.prixTotal}');
}

// 3. User valide la transaction
final dto = ValidateTransactionDto(
  valide: true,
  commentaire: 'Quantité vérifiée et conforme',
);

final validated = await TransactionPartenaritService.validateTransaction(
  transaction.id,
  dto,
);

print('✅ Transaction validée le ${validated.dateValidation}');
```

### Scénario 3: Société corrige une erreur

```dart
// 1. Société se rend compte d'une erreur avant validation
final transaction = await TransactionPartenaritService.getTransactionById(5);

if (transaction.isEnAttente()) {
  // 2. Modifier la transaction
  final dto = UpdateTransactionPartenaritDto(
    quantite: '2100 Kg',  // Correction
    prixTotal: '2,100,000 CFA',
    commentaire: 'Correction quantité - pesée finale',
  );

  final updated = await TransactionPartenaritService.updateTransaction(5, dto);
  print('✅ Transaction mise à jour');
} else {
  print('❌ Transaction déjà validée, modification impossible');
}
```

---

## 🔄 Intégration avec autres services

### 1. AbonnementAuthService

```dart
// Vérifier que l'user a un abonnement premium avant d'accéder aux transactions
final abonnements = await AbonnementAuthService.getActiveSubscriptions();
final hasPremium = abonnements.any((a) => a.societeId == societeId);

if (!hasPremium) {
  print('❌ Abonnement premium requis pour voir les transactions');
  return;
}

// Charger les transactions
final transactions = await TransactionPartenaritService
    .getTransactionsForPage(pageId);
```

### 2. InformationPartenaireService

```dart
// Dans la page partenariat, afficher les deux onglets:
// - Tab 1: Transactions (TransactionPartenaritService)
// - Tab 2: Informations partenaire (InformationPartenaireService)

TabController(length: 2, vsync: this);

TabBarView(
  children: [
    TransactionTabContent(pageId: pageId),
    InformationsPartenairePage(pageId: pageId),
  ],
)
```

---

## 📝 Résumé des DTOs

### CreateTransactionPartenaritDto
```dart
CreateTransactionPartenaritDto({
  required int pageId,
  required int userId,
  required String periode,
  required String quantite,
  required String prixUnitaire,
  required String prixTotal,
  String? commentaire,
})
```

### UpdateTransactionPartenaritDto
```dart
UpdateTransactionPartenaritDto({
  String? periode,
  String? quantite,
  String? prixUnitaire,
  String? prixTotal,
  String? commentaire,
})
```

### ValidateTransactionDto
```dart
ValidateTransactionDto({
  required bool valide,      // true = valider, false = rejeter
  String? commentaire,
})
```

---

**Dernière mise à jour:** 2025-12-13
**Fichier créé:** `lib/services/partenariat/transaction_partenariat_service.dart`
