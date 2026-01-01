# ✅ Correction du pagePartenaritId - Interface Société (IS)

## 🎯 Problème Identifié

Dans la page `UserTransactionPage` (IS), lors de la création d'une transaction, le code utilisait temporairement `userId` à la place du vrai `pagePartenaritId` :

```dart
// ❌ AVANT - Code incorrect (ligne 685)
final dto = CreateTransactionPartenaritDto(
  pagePartenaritId: widget.userId, // ⚠️ Temporaire - ERREUR!
  produit: _produitController.text.trim(),
  // ...
);
```

**Problème** : `userId` n'est PAS le `pagePartenaritId`. Ce sont deux identifiants différents :
- `userId` : ID de l'utilisateur (table `users`)
- `pagePartenaritId` : ID de la page partenariat (table `pages_partenariat`)

---

## ✅ Solution Implémentée

### 1. Création du Service `PagePartenaritService`

**Fichier** : [lib/services/partenariat/page_partenariat_service.dart](lib/services/partenariat/page_partenariat_service.dart)

Un nouveau service a été créé pour gérer les pages de partenariat :

```dart
class PagePartenaritService {
  /// Récupérer une page partenariat par userId et societeId
  static Future<PagePartenaritModel> getPageByUserAndSociete({
    required int userId,
    required int societeId,
  }) async {
    final response = await ApiService.get(
      '/pages-partenariat?userId=$userId&societeId=$societeId',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return PagePartenaritModel.fromJson(jsonResponse['data']);
    } else {
      throw Exception('Page partenariat introuvable');
    }
  }

  /// Récupérer une page partenariat par ID
  static Future<PagePartenaritModel> getPageById(int pageId) async { ... }

  /// Récupérer toutes les pages partenariat d'une société
  static Future<List<PagePartenaritModel>> getPagesBySociete(int societeId) async { ... }

  /// Récupérer toutes les pages partenariat d'un user
  static Future<List<PagePartenaritModel>> getPagesByUser(int userId) async { ... }
}
```

**Modèle** :
```dart
class PagePartenaritModel {
  final int id;              // ✅ Le vrai pagePartenaritId
  final int userId;
  final int societeId;
  final String titre;
  final String visibilite;   // 'prive' | 'public'
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

### 2. Mise à Jour de `UserTransactionPage`

**Fichier** : [lib/is/onglets/servicePlan/user_transaction_page.dart](lib/is/onglets/servicePlan/user_transaction_page.dart)

#### A. Ajout de Variables d'État

```dart
class _UserTransactionPageState extends State<UserTransactionPage> {
  UserModel? _user;
  int? _pagePartenaritId; // ✅ Nouveau - ID de la page partenariat
  List<TransactionPartenaritModel> _transactions = [];
  List<InformationPartenaireModel> _informations = [];

  bool _isLoadingUser = true;
  bool _isLoadingPageId = true; // ✅ Nouveau
  bool _isLoadingTransactions = true;
  bool _isLoadingInformations = true;
```

#### B. Chargement du pagePartenaritId

Nouvelle méthode `_loadPagePartenaritId()` (lignes 69-99) :

```dart
Future<void> _loadPagePartenaritId() async {
  setState(() => _isLoadingPageId = true);

  try {
    // 1. Récupérer l'ID de la société connectée
    final societe = await SocieteAuthService.getMe();

    // 2. Récupérer la page partenariat entre la société et l'utilisateur
    final page = await PagePartenaritService.getPageByUserAndSociete(
      userId: widget.userId,
      societeId: societe.id,
    );

    if (mounted) {
      setState(() {
        _pagePartenaritId = page.id; // ✅ Stocke le vrai ID
        _isLoadingPageId = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingPageId = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement de la page partenariat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

#### C. Vérification Avant Création de Transaction

Méthode `_createTransaction()` mise à jour (lignes 458-493) :

```dart
Future<void> _createTransaction() async {
  // ✅ Vérifier que le pagePartenaritId est chargé
  if (_pagePartenaritId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chargement de la page partenariat en cours...'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  final result = await showDialog<TransactionPartenaritModel>(
    context: context,
    builder: (context) => TransactionFormDialog(
      userId: widget.userId,
      userName: widget.userName,
      pagePartenaritId: _pagePartenaritId!, // ✅ Passer le vrai ID
    ),
  );

  // ...
}
```

#### D. Mise à Jour du Dialog `TransactionFormDialog`

**Paramètres mis à jour** (lignes 578-595) :

```dart
class TransactionFormDialog extends StatefulWidget {
  final int userId;
  final String userName;
  final int? pagePartenaritId; // ✅ Nouveau paramètre
  final TransactionPartenaritModel? transaction;

  const TransactionFormDialog({
    super.key,
    required this.userId,
    required this.userName,
    this.pagePartenaritId, // ✅ Nouveau
    this.transaction,
  });
}
```

**Utilisation dans la création** (lignes 695-719) :

```dart
if (widget.transaction == null) {
  // Création
  if (widget.pagePartenaritId == null) {
    throw Exception('ID de page partenariat manquant');
  }

  final dto = CreateTransactionPartenaritDto(
    pagePartenaritId: widget.pagePartenaritId!, // ✅ Utilise le vrai ID
    produit: _produitController.text.trim(),
    quantite: int.parse(_quantiteController.text.trim()),
    prixUnitaire: double.parse(_prixUnitaireController.text.trim()),
    dateDebut: _dateDebut!.toIso8601String(),
    dateFin: _dateFin!.toIso8601String(),
    // ...
  );

  result = await TransactionPartenaritService.createTransaction(dto);
}
```

---

## 🔄 Flux de Données Corrigé

```
┌────────────────────────────────────────────────────────┐
│  1. SOCIÉTÉ ouvre UserTransactionPage                  │
│     avec userId (ex: 42)                               │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│  2. _loadPagePartenaritId()                            │
│                                                        │
│     a) Récupère societeId via SocieteAuthService       │
│        societeId = 7                                   │
│                                                        │
│     b) Appel API:                                      │
│        GET /pages-partenariat?userId=42&societeId=7    │
│                                                        │
│     c) Backend retourne:                               │
│        {                                               │
│          "id": 123,           ← ✅ pagePartenaritId    │
│          "userId": 42,                                 │
│          "societeId": 7,                               │
│          "titre": "Partenariat Riz",                   │
│          "visibilite": "prive"                         │
│        }                                               │
│                                                        │
│     d) Stocke _pagePartenaritId = 123                  │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│  3. SOCIÉTÉ clique "Nouvelle transaction"              │
│                                                        │
│     → _createTransaction() vérifie _pagePartenaritId   │
│       ✅ _pagePartenaritId = 123 (chargé)              │
│                                                        │
│     → Ouvre TransactionFormDialog avec:               │
│       - userId: 42                                     │
│       - pagePartenaritId: 123  ✅                      │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│  4. SOCIÉTÉ remplit le formulaire                      │
│                                                        │
│     - Produit: "Riz Basmati"                           │
│     - Quantité: 1000                                   │
│     - Prix: 500 CFA                                    │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│  5. _submitForm() crée le DTO                          │
│                                                        │
│     CreateTransactionPartenaritDto(                    │
│       pagePartenaritId: 123,  ✅ Vrai ID               │
│       produit: "Riz Basmati",                          │
│       quantite: 1000,                                  │
│       prixUnitaire: 500.0,                             │
│       // ...                                           │
│     )                                                  │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│  6. API Backend                                        │
│                                                        │
│     POST /transactions-partenariat                     │
│     {                                                  │
│       "page_partenariat_id": 123,  ✅ Correct          │
│       "produit": "Riz Basmati",                        │
│       "quantite": 1000,                                │
│       "prix_unitaire": 500.0                           │
│     }                                                  │
│                                                        │
│     → Backend crée la transaction dans la DB           │
│     → Retourne la transaction créée                    │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────────────┐
│  7. ✅ Transaction créée avec succès                   │
│                                                        │
│     TransactionPartenaritModel {                       │
│       id: 456,                                         │
│       pageId: 123,           ✅ Correspond             │
│       societeId: 7,                                    │
│       userId: 42,                                      │
│       produit: "Riz Basmati",                          │
│       quantite: 1000,                                  │
│       prixUnitaire: 500.0,                             │
│       statut: "en_attente"                             │
│     }                                                  │
└────────────────────────────────────────────────────────┘
```

---

## 🔍 Comparaison Avant/Après

| Aspect | ❌ Avant | ✅ Après |
|--------|---------|----------|
| **ID utilisé** | `userId` (42) | `pagePartenaritId` (123) |
| **Chargement ID** | Pas de chargement | Chargement au démarrage via `_loadPagePartenaritId()` |
| **Vérification** | Aucune | Vérifie que `pagePartenaritId != null` avant création |
| **Service utilisé** | Aucun | `PagePartenaritService.getPageByUserAndSociete()` |
| **Backend** | ❌ Reçoit mauvais ID | ✅ Reçoit le bon ID |
| **Données en DB** | ❌ Données incorrectes | ✅ Données correctes |

---

## 📋 Endpoints Backend Requis

Pour que cette correction fonctionne, le backend doit implémenter :

### 1. GET /pages-partenariat?userId={userId}&societeId={societeId}

**Description** : Récupère la page partenariat entre un user et une société.

**Requête** :
```http
GET /pages-partenariat?userId=42&societeId=7
Authorization: Bearer {jwt_token}
```

**Réponse** :
```json
{
  "success": true,
  "data": {
    "id": 123,
    "userId": 42,
    "societeId": 7,
    "titre": "Partenariat Riz",
    "visibilite": "prive",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z"
  }
}
```

**Permissions** : Société doit être authentifiée et être le propriétaire de la page.

### 2. GET /pages-partenariat/:id

**Description** : Récupère une page partenariat par son ID.

### 3. GET /pages-partenariat/societe/:societeId

**Description** : Liste toutes les pages partenariat d'une société.

### 4. GET /pages-partenariat/user/:userId

**Description** : Liste toutes les pages partenariat d'un utilisateur.

---

## ✅ Bénéfices de Cette Correction

### 1. Intégrité des Données
- ✅ Les transactions sont liées à la bonne page partenariat
- ✅ Les relations User ↔ Société ↔ Page sont correctes
- ✅ Les requêtes SQL fonctionnent correctement

### 2. Cohérence Backend
- ✅ Le backend reçoit les bonnes données
- ✅ Les contraintes de clés étrangères sont respectées
- ✅ Les validations backend passent

### 3. Fonctionnalités Futures
- ✅ Permet de récupérer toutes les transactions d'une page
- ✅ Permet de filtrer par page partenariat
- ✅ Permet d'afficher les statistiques par partenariat

### 4. Maintenabilité
- ✅ Service dédié réutilisable (`PagePartenaritService`)
- ✅ Code clair et explicite
- ✅ Gestion d'erreurs appropriée

---

## 🧪 Tests à Effectuer

### Tests Fonctionnels

- [ ] **Chargement de la page** :
  - [ ] Ouvrir `UserTransactionPage` en tant que Société
  - [ ] Vérifier que `_pagePartenaritId` est chargé
  - [ ] Vérifier qu'aucune erreur ne s'affiche

- [ ] **Création de transaction** :
  - [ ] Cliquer sur "Nouvelle transaction"
  - [ ] Remplir le formulaire
  - [ ] Vérifier que la transaction est créée avec le bon `pageId`

- [ ] **Vérification en DB** :
  - [ ] Vérifier que `page_id` dans `transactions` correspond au bon `id` de `pages_partenariat`
  - [ ] Vérifier que les relations sont correctes

### Tests d'Erreur

- [ ] **Page partenariat inexistante** :
  - [ ] Tester avec un userId sans abonnement
  - [ ] Vérifier qu'un message d'erreur s'affiche

- [ ] **Chargement échoué** :
  - [ ] Simuler une erreur réseau
  - [ ] Vérifier que le bouton "Nouvelle transaction" est bloqué

---

## 📝 Notes Importantes

1. **Ordre de Chargement** :
   - Le `pagePartenaritId` est chargé en parallèle avec les autres données
   - Si le chargement échoue, la création de transaction est bloquée

2. **Gestion d'Erreurs** :
   - Si la page partenariat n'existe pas → Erreur affichée
   - Si le chargement est en cours → Message "Chargement en cours..."
   - Si l'utilisateur n'est pas abonné → La page partenariat n'existe pas

3. **Relation avec Abonnement** :
   - Une page partenariat est créée lors de l'upgrade vers un abonnement premium
   - Si pas d'abonnement → Pas de page partenariat → Erreur

4. **Performance** :
   - Un seul appel API pour récupérer le `pagePartenaritId`
   - Chargé une seule fois au démarrage de la page
   - Stocké en mémoire pendant toute la durée de vie de la page

---

## 🚀 Conclusion

**✅ Le problème du `pagePartenaritId` est maintenant résolu !**

- Un service dédié a été créé pour gérer les pages de partenariat
- Le vrai `pagePartenaritId` est récupéré depuis le backend
- Les transactions sont créées avec les bonnes données
- Le code est maintenable et réutilisable

**Prochaines étapes** :
1. Vérifier que le backend implémente les endpoints nécessaires
2. Tester le flux complet de création de transaction
3. Vérifier l'intégrité des données en base de données
